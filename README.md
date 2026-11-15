Start with
```
docker compose up -d
```

Connect as the owner
```
psql "postgresql://postgres@localhost:5432/market"
```

Connect as the analyst
```
psql "postgresql://analyst_user@localhost:5432/market"
```
