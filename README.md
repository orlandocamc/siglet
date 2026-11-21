# SIGLET

Web system for managing laboratory equipment inventory: loans, lab reservations,
maintenance, incidents, roles and permissions. Built with Django (MVT) on MySQL, with
stored procedures for the core operations and a chat assistant endpoint.

Course project for *Bases de Datos* (Databases), Universidad Iberoamericana, Mexico City.
Developed **November - December 2025** (SQL and ER model 24-26 Nov 2025; Django app until
16 Dec 2025; Railway configuration added 11 Feb 2026).

## Team

- Team: **Orlando Camacho, Mario Ureña, Ricardo Ponce**.
- Orlando Camacho: Django backend (together with Mario Ureña), UI design and frontend,
  chat assistant integration, and the integration of the MySQL database with AWS.

## What is here

| Path | Content |
|---|---|
| `core/`, `siglet_web/`, `manage.py` | Django application (models, views, templates, static files) |
| `sql/2PuntoDeControl_ProcedimientosAlmacenados.sql` | Schema and stored procedures (checkpoint 2) |
| `sql/3PuntoDeControlDemo.sql` | Checkpoint 3 demo script |
| `sql/demoScript.sql` | `sp_seed_full_demo_environment`: generates fictitious demo data |
| `docs/SIGLET.mwb` | MySQL Workbench model |
| `docs/er-diagram.png` | ER diagram rendered from the `.mwb` by `tools/export_er.py` (tables placed as in Workbench; FK lines are drawn centre to centre, so they may cross other boxes) |
| `docs/DOCUMENTACION BACKEND Y FRONTEND SIGLET.pdf` | Backend/frontend documentation (Spanish): MVT, data flow, pseudocode |

## Run locally

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
# MySQL 8: create database SIGLETdB and load sql/2PuntoDeControl_ProcedimientosAlmacenados.sql,
# then optionally sql/demoScript.sql and CALL sp_seed_full_demo_environment();
export SECRET_KEY=change-me
export OPENAI_API_KEY=...      # only needed for the chat assistant view
python manage.py runserver
```

Database settings (local root user, empty password) are in `siglet_web/settings.py`; change them for your setup.

## Notes on what was removed or changed for publication

- No SFTP configuration, database dumps (they contained password hashes and a cloud database hostname) or the lab inventory CSV (`datos.csv`, institutional asset serial numbers) are included.
  Demo data comes from the fictitious seed procedure instead.
- The chat view originally had an API key written in the source. It now reads `OPENAI_API_KEY` from the environment.
- Known limitations of this academic project: the custom `user` table stores demo passwords in plain text, `DEBUG` defaults to on and `ALLOWED_HOSTS` is `*`. Do not deploy as is.

## Date of this repository

This repository was created on 21 November 2026 from the project files; its first commit date is the real upload date, not the development date given above.
