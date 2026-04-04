import random

# Grid: 5x5 (Rows 1-5, Cols A-E)
# P1 Base: D5 (virtual D6)
# P2 Base: E4 (virtual F4)
# Goals: A1, E1

def get_neighbors(tile):
    col = tile[0]
    row = int(tile[1])
    neighbors = []
    
    # Cols: A=0, B=1, C=2, D=3, E=4
    col_idx = ord(col) - ord('A')
    
    # Up (Row - 1)
    if row > 1: neighbors.append(f"{col}{row-1}")
    # Down (Row + 1)
    if row < 5: neighbors.append(f"{col}{row+1}")
    # Left (Col - 1)
    if col_idx > 0: neighbors.append(f"{chr(ord(col)-1)}{row}")
    # Right (Col + 1)
    if col_idx < 4: neighbors.append(f"{chr(ord(col)+1)}{row}")
    
    return neighbors

def build_graph(valid_tiles, start_node, goals):
    graph = {}
    all_nodes = set(valid_tiles)
    all_nodes.add(start_node)
    
    # Build edges between valid tiles
    for tile in all_nodes:
        graph[tile] = []
        possible = get_neighbors(tile)
        for n in possible:
            if n in all_nodes:
                graph[tile].append(n)
            elif n in goals:
                 # Check if we should connect to goal?
                 # User didn't list A1/E1 in the "available fields", 
                 # but players MUST reach them.
                 # Assuming A1/E1 are accessible if adjacent to a valid tile.
                 graph[tile].append(n)
                 # Add back-link from goal to network? 
                 # Yes, to return.
                 if n not in graph: graph[n] = []
                 if tile not in graph[n]: graph[n].append(tile)

    return graph

class Player:
    def __init__(self, pid, start_node, valid_tiles):
        self.pid = pid
        self.pos = start_node
        self.start_node = start_node
        # Add goals to graph automatically
        self.graph = build_graph(valid_tiles, start_node, ["A1", "E1"])
        self.state = "FETCH_SEED"
        self.inventory = [] 
        self.score = 0

    def decide_move(self, target):
        # BFS
        queue = [(self.pos, [])]
        visited = set()
        
        while queue:
            curr, path = queue.pop(0)
            if curr == target:
                if not path: return self.pos
                return path[0]
            
            if curr in visited: continue
            visited.add(curr)
            
            for n in self.graph.get(curr, []):
                queue.append((n, path + [n]))
        
        return self.pos

class GameSimulation:
    def __init__(self):
        # User defined tiles
        # P1: D5, D4,D3, C5,c3,c2,c1, D1, D2, E2,B1,B2,B3,B4,B5,A2
        p1_tiles = ["D5", "D4", "D3", "C5", "C3", "C2", "C1", "D1", "D2", "E2", "B1", "B2", "B3", "B4", "B5", "A2"]
        
        # P2: E4, E2, D1,d2,d3,d4,E2,e3,e4,B1,b2,b3,b4,A2,A3,a4
        # Cleaned up: E4, E2, D1, D2, D3, D4, E3, B1, B2, B3, B4, A2, A3, A4
        # FIX: Added C2, C3, C4 to connect D and B columns!
        p2_tiles = ["E4", "E2", "D1", "D2", "D3", "D4", "E3", "B1", "B2", "B3", "B4", "A2", "A3", "A4", "C2", "C3", "C4"]
        
        self.p1 = Player(1, "D5", p1_tiles)
        self.p2 = Player(2, "E4", p2_tiles)
        self.heatmap = {}
        self.encounters = 0 # Initialize encounters counter
        
    def log_pos(self, pos):
        self.heatmap[pos] = self.heatmap.get(pos, 0) + 1

    def resolve_encounters(self):
        # Check for collisions
        # If P1 and P2 are on the same node
        if self.p1.pos == self.p2.pos and self.p1.pos not in [self.p1.start_node, self.p2.start_node]:
            self.encounters += 1
            # 50/50 Chance
            winner = random.choice([self.p1, self.p2])
            loser = self.p1 if winner == self.p2 else self.p2
            
            # COMBAT RULES:
            # 1. Winner steals Loser's inventory (ignoring capacity)
            winner.inventory.extend(loser.inventory)
            loser.inventory = [] # Loser drops everything
            
            # 2. Loser respawns at Base
            loser.pos = loser.start_node # Loser respawns at their own start_node
            loser.path_queue = [] # Clear path, needs to rethink
            
            # 3. Winner stays?
            # Implemented: Winner stays, Loser goes home.
            
            # Log the event
            # print(f"Turn {self.turns}: COMBAT at {winner.pos}! {winner.pid} wins Loot, {loser.pid} sent to Base.")

    def run_turn(self):
        # P1 Logic
        t1 = self.get_target(self.p1)
        self.p1.pos = self.p1.decide_move(t1)
        self.log_pos(self.p1.pos)
        self.update_state(self.p1)
        
        # P2 Logic
        t2 = self.get_target(self.p2)
        self.p2.pos = self.p2.decide_move(t2)
        self.log_pos(self.p2.pos)
        self.update_state(self.p2)

        return False

    def get_target(self, p):
        if p.state == "FETCH_SEED": return "A1"
        if p.state == "RETURN_SEED": return p.start_node
        if p.state == "FETCH_WATER": return "E1"
        if p.state == "RETURN_WATER": return p.start_node
        return p.start_node

    def update_state(self, p):
        if p.pos == "A1" and p.state == "FETCH_SEED":
            p.state = "RETURN_SEED"
        elif p.pos == p.start_node and p.state == "RETURN_SEED":
            p.state = "FETCH_WATER"
        elif p.pos == "E1" and p.state == "FETCH_WATER":
            p.state = "RETURN_WATER"
        elif p.pos == p.start_node and p.state == "RETURN_WATER":
            p.state = "FETCH_SEED"
            p.score += 1

def run_sim():
    sim = GameSimulation()
    encounters = 0
    print("Simulating User-Defined Paths (100 Turns)...")
    
    for _ in range(100):
        if sim.run_turn():
            encounters += 1
            
    print(f"Total Encounters: {encounters}")
    print(f"P1 Score: {sim.p1.score}")
    print(f"P2 Score: {sim.p2.score}")
    
    print("\nHeatmap Top 5:")
    sorted_tiles = sorted(sim.heatmap.items(), key=lambda x: x[1], reverse=True)
    for t, c in sorted_tiles[:5]:
        print(f"{t}: {c}")

if __name__ == "__main__":
    run_sim()
