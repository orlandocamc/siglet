"""Render the ER diagram stored in a MySQL Workbench .mwb file to PNG
(no Workbench needed). Usage: python tools/export_er.py docs/SIGLET.mwb docs/er-diagram.png
Requires matplotlib. Tables keep the positions they have in the Workbench diagram."""
import sys, zipfile
import xml.etree.ElementTree as ET
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

src, dst = sys.argv[1], sys.argv[2]
root = ET.fromstring(zipfile.ZipFile(src).read("document.mwb.xml"))


def val(e, key):
    for c in e:
        if c.get("key") == key:
            return c.text or ""


tables, columns = {}, {}
for e in root.iter("value"):
    if e.get("struct-name") == "db.mysql.Table":
        tables[e.get("id")] = e
        cols = []
        for c in e:
            if c.get("key") == "columns":
                for col in c:
                    cols.append(val(col, "name"))
        columns[e.get("id")] = cols
# table figures (positions)
pos = {}
for e in root.iter("value"):
    if e.get("struct-name") == "workbench.physical.TableFigure":
        link = next(c for c in e if c.get("key") == "table").text
        pos[link] = tuple(float(val(e, k)) for k in ("left", "top", "width", "height"))
# foreign keys: table -> referenced table
edges = []
for t_id, t in tables.items():
    for c in t:
        if c.get("key") == "foreignKeys":
            for fk in c:
                ref = next((x.text for x in fk if x.get("key") == "referencedTable"), None)
                if ref in tables:
                    edges.append((t_id, ref))

fig, ax = plt.subplots(figsize=(22, 30))
for a, b in edges:
    if a in pos and b in pos:
        (l1, t1, w1, h1), (l2, t2, w2, h2) = pos[a], pos[b]
        ax.plot([l1 + w1 / 2, l2 + w2 / 2], [t1 + h1 / 2, t2 + h2 / 2], color="#888", lw=0.8, zorder=1)
for t_id, (l, t, w, h) in pos.items():
    cols = columns[t_id]
    h = 22 + 14 * len(cols)
    ax.add_patch(Rectangle((l, t), max(w, 150), h, fc="#e8f0f8", ec="#335", zorder=2))
    ax.text(l + 4, t + 4, val(tables[t_id], "name"), fontsize=8, weight="bold", va="top", zorder=3)
    for i, c in enumerate(cols):
        ax.text(l + 8, t + 20 + 14 * i, c, fontsize=6, va="top", zorder=3)
ax.autoscale()
ax.invert_yaxis()
ax.set_aspect("equal")
ax.axis("off")
fig.savefig(dst, dpi=110, bbox_inches="tight")
print(f"{len(pos)} tables, {len(edges)} foreign keys -> {dst}")
