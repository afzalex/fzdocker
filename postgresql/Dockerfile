FROM tensorchord/vchord-scratch:pg17-v1.1.1 AS vchord_scratch
FROM postgres:17-bookworm

RUN apt-get update && apt-get install -y postgresql-17-pgvector

COPY --from=vchord_scratch / /

CMD ["postgres", "-c", "shared_preload_libraries=vchord,vector"]

EXPOSE 5432
