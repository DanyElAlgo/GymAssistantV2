---
status: accepted
---

# Backend: FastAPI with PostgreSQL, packaged in Docker

The cloud side is a REST API in Python with FastAPI (Pydantic schemas, OpenAPI generated from the code), SQLAlchemy with Alembic migrations, and PostgreSQL. It authenticates with JWT (role carried in the token; identity always taken from the token, never from the request body) and hashes passwords with Argon2id. FastAPI's generated OpenAPI keeps the contract in Diseño §11 checkable, and PostgreSQL provides the partial unique indexes and aggregate queries the data model relies on. The hosting provider is still undecided; Docker keeps development and production on the same container in the meantime.

Source: Diseño, "Decisiones que fijan este diseño", §1.4, §8.1, §11.
