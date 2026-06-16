import numpy as np
import polars as pl
import networkx as nx
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# 1) DAG definieren
G = nx.DiGraph([("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")])
order = list(nx.topological_sort(G))
pos = nx.spring_layout(G, seed=7)

rng = np.random.default_rng(42)

# 2) Zuteilungsregeln (strukturelle Gleichungen)
def p_A(values):
    return 0.30

def p_B(values):
    return np.clip(0.10 + 0.70 * values["A"], 0.0, 1.0)

def p_C(values):
    return np.clip(0.20 + 0.50 * values["A"], 0.0, 1.0)

def p_D(values):
    return np.clip(0.05 + 0.40 * values["B"] + 0.40 * values["C"], 0.0, 1.0)

prob_fn = {"A": p_A, "B": p_B, "C": p_C, "D": p_D}

# 3) Ein Durchlauf + Historie für Animation
def simulate_one(G, order, prob_fn, rng):
    values = {}
    history = []

    for node in order:
        p = float(prob_fn[node](values))
        x = int(rng.binomial(1, p))
        values[node] = x

        step_state = {}
        for n in G.nodes:
            if n in values:
                step_state[n] = {"status": "won" if values[n] == 1 else "lost", "x": values[n], "p": p if n == node else None}
            else:
                step_state[n] = {"status": "pending", "x": None, "p": None}
        history.append(step_state)

    return values, history

# 4) Mehrere Durchläufe als Datentabelle (für dein Tool)
def simulate_many(n_runs, G, order, prob_fn, seed=42):
    rng_local = np.random.default_rng(seed)
    rows = []
    for run_id in range(1, n_runs + 1):
        vals, _ = simulate_one(G, order, prob_fn, rng_local)
        rows.append({"run": run_id, **vals})
    return pl.DataFrame(rows)

# 5) Animation für einen Lauf
def animate_history(G, pos, history, interval=1200):
    fig, ax = plt.subplots(figsize=(6, 4.5))

    def node_color(state):
        s = state["status"]
        if s == "won":
            return "#2ca25f"
        if s == "lost":
            return "#de2d26"
        return "#bdbdbd"

    def update(frame):
        ax.clear()
        nx.draw_networkx_edges(G, pos, ax=ax, arrows=True, arrowstyle="-|>", arrowsize=18, width=1.6)

        colors = [node_color(history[frame][n]) for n in G.nodes]
        nx.draw_networkx_nodes(G, pos, ax=ax, node_color=colors, node_size=1400, edgecolors="#333333")

        labels = {}
        for n in G.nodes:
            st = history[frame][n]
            if st["status"] == "pending":
                labels[n] = f"{n}\n?"
            else:
                labels[n] = f"{n}\nx={st['x']}"
        nx.draw_networkx_labels(G, pos, labels=labels, ax=ax, font_size=10, font_weight="bold")

        resolved = [n for n in G.nodes if history[frame][n]["status"] != "pending"]
        title_nodes = ", ".join(resolved)
        ax.set_title(f"Ziehungsschritt {frame + 1}/{len(history)}  |  gesetzt: {title_nodes}")
        ax.set_axis_off()

    anim = FuncAnimation(fig, update, frames=len(history), interval=interval, repeat=False)
    return anim

# --- Ausführen ---
values_one, history_one = simulate_one(G, order, prob_fn, rng)
allocations = simulate_many(n_runs=200, G=G, order=order, prob_fn=prob_fn, seed=99)
anim = animate_history(G, pos, history_one)

# Optional speichern:
# anim.save("dag_lottery.gif", writer="pillow", fps=1)

allocations