# Repository Structure

What each of the six repositories holds, directory by directory, and where each part runs.
Files are described where they are today; nothing here implies a move. Scheduling, launchd and
the Docker images reference these paths.

*Last checked: 2026-11-08.*

## The six repositories

| Repo | Role | Language | Runs |
|---|---|---|---|
| [`quant_data`](#quant_data--data-research-and-ml) | Collection, LLM labelling, features, models, backtests, Airflow DAGs | Python 3.11 | Host Airflow scheduler (launchd) |
| [`quant_ai`](#quant_ai--ai-service-and-portfolio-advisor) | RAG, ReAct research agent, MCP server, portfolio advisor (`markets/`) | Python 3.11, FastAPI | Host process on :18000 (launchd) |
| [`quant_api`](#quant_api--rest-api) | REST API in front of MongoDB, Kafka signal events, JWT auth | Java 21, Spring Boot 3 | Docker, :18081 |
| [`quant_ui`](#quant_ui--dashboard) | Dashboard SPA | TypeScript, React 18, Vite | Docker (nginx), :18080 |
| [`quant_docker`](#quant_docker--platform) | Compose file, image pins, platform README, project plan | YAML, shell | — |
| [`quant_keycloak`](#quant_keycloak--identity) | Keycloak image and the `quant` realm | JSON, shell | Docker, :18082 |

### Runtime topology

```
 Host (macOS, launchd)                          Docker (quant_docker/docker-compose.yml)
 ─────────────────────                          ─────────────────────────────────────────
 Airflow scheduler  ── quant_data DAGs ──┐      mongo6 :37018      MongoDB (quant_data db)
 quant_ai :18000    ── RAG / agent / MCP ┤      qdrant :26333      vector index (news RAG)
 LM Studio :1234    ── local LLMs        ┤      airflow-postgres   Airflow metadata, GDELT queue
                                         ├────▶ quant_api :18081   REST API (+ Kafka)
                                         │      quant_ui  :18080   dashboard (nginx)
                                         │      quant_keycloak     OIDC / JWT
                                         │      kafka, mlflow :15050
```

quant_ai and the Airflow scheduler run on the host because, under the VPN, containers cannot
reach LM Studio on `127.0.0.1:1234`. The `quant_data` container's in-process scheduler is kept
disabled by environment flags in the compose file; scheduling belongs to host Airflow.

### Data outside the repositories

| Where | What |
|---|---|
| MongoDB `quant_data` | Articles (`news_articles_*`), labels, features, `daily_signals`, positions, performance, prices |
| `/Volumes/Data4T/universe/` | Universe expansion: company rules, candidate lists, backfill state |
| `/Volumes/Data4T/rule_check/` | Labelling and distillation experiments (test sets, adapters, reports) |
| `/Volumes/Data4T/backups/<date>/` | File backups taken before edits (kept out of the repositories) |
| `~/Library/Application Support/quant_ai/` | Host helpers for LM Studio and disk monitoring |

---

## quant_data — data, research and ML

| Path | Contents |
|---|---|
| `airflow/dags/` | The 14 DAG files. `_host_common.py` holds shared host settings; the rest are pipelines: `intraday_news` (every 30 min), `daily_signal_pipeline`, `daily_advice`, `price_history_backfill`, `market_snapshots`, `retail_sentiment`, `weekly_inst13f_holdings`, `weekly_model_training`, `keyword_refresh`, `gdelt_batch_verify`, `news_validation`, and the two manual backfills `backfill_1_collect_and_match` / `backfill_2_enrich_and_features`. Run logs go to `airflow/logs/` (ignored, 30-day retention). |
| `collectors/news/gdelt/` | GDELT GKG collection: historical and daily collectors, full-text fetch, company rules and `special_rules/` (ambiguous names, domain kills). Most of the repo's collector code. |
| `collectors/news/{finnhub,newsapi,yahoo}/` | Other news sources; `_canonical.py` normalises them to one article shape. |
| `collectors/stock/` | Daily price history and universe tools (`expand_universe.py`, deduplication). |
| `collectors/{analyst,inst_13f,macro,market,premarket,retail}/` | Analyst ratings, 13F holdings, macro series, market snapshots, pre-market quotes, retail sentiment. |
| `research/labeling/` | LLM labelling: `slm_company_match_v2.py` (is this article about the company?), `llm_enrich_articles.py` (event type, sentiment, strength, Pass A / Pass B), `merge_ab_labels.py`, `slm_relevance_rescore.py`. |
| `research/features/` | `daily_symbol_features.py` builds the feature store (news, LLM, earnings, price, alternative data); syndication measurement; earnings events and reactions. |
| `research/signals/` | `score_daily_signals.py` (daily composite ranks, walk-forward fitted weights in `fitted_weights.json`) and `track_positions.py` (paper positions). |
| `research/models/` | Trained models: baseline ranking models, earnings policy and earnings pulse (incl. 1D-CNN challenger), daily advice, barrier model, drop-rebound, news events, calendar events, risk budget. |
| `research/lab/` | Event-strategy lab: one evaluation protocol, model zoo, MLflow tracking. |
| `research/rl/` | Action RL: action grammar, exact simulator, daily and peer variants, learners. |
| `research/backtest/` | Portfolio and event-driven backtests, factor analysis, factor lab. |
| `research/quality/` | Data-quality checks and the news-validation audit. |
| `research/universe/` | `build_universe.py`: point-in-time S&P 500 + Nasdaq-100 membership. |
| `tools/` | Operational scripts: news backfills (`backfill_symbol_news.py`, `backfill_universe_news.py`), rule generation / validation / optimisation, weekly `keyword_refresh.py`, `gkg_parquet.py`, `llm_judge.py`, and `lm_session.py` (the shared LM Studio lock every LLM task runs under). |
| `scripts/` | One-off benchmarks and environment setup. |
| `tests/` | pytest suite (features, regime scoring, positions, RL simulator, LM session, pulse scrubber). |
| `docs/` | Research write-ups: `RESEARCH_FACTORS.md`, `RESEARCH_SUMMARY.md`. |
| `main.py`, `api_server.py`, `health_checker.py`, `scheduler/`, `test_db_connection.py` | Docker image entry point (script API on :8000, health monitor, the disabled in-container scheduler) and the image's health check. |
| `Dockerfile`, `requirements*.txt`, `pytest.ini`, `ty.toml`, `.github/workflows/` | Image build, dependencies, test and type-check config, CI. |

## quant_ai — AI service and portfolio advisor

| Path | Contents |
|---|---|
| `main.py` | FastAPI app: RAG Q&A (`/api/ask`), news search (`/api/ask/news`), agent streaming, and mounts the `markets/` API. |
| `agent.py` | Hand-written ReAct loop (no framework); tools discovered at runtime over MCP. |
| `mcp_server.py`, `mcp_client.py` | MCP server (stdio) exposing read-only platform tools, and the client the agent uses. |
| `news_rag.py` | News retrieval: hybrid search, optional cross-encoder rerank. |
| `portfolio_agent.py` | Portfolio research agent built on the same tools. |
| `injection_guard.py`, `service_auth.py` | Prompt-injection screening; service-to-service credentials for quant_api. |
| `markets/` | Portfolio and markets service: holdings and trades (`portfolio.py`), advisor and lot advisor, daily action (`daily_action.py`, `model_advice.py`, `risk_budget.py`, `risk_rules.py`), catalysts and events, earnings pulse watch (`pulse.py`), market briefs, global markets and indices, predictions scoring, keyword review, task monitor and schedule, phone page (`mobile.py`), LAN auth, `api.py` (routes). |
| `knowledge/` | Markdown documents embedded for RAG Q&A. |
| `eval/` | Retrieval and generation evaluation (R series): query sets, judge pools, rerank sweeps, scoring, the Claude reference labels. |
| `tools/` | News indexing into Qdrant, search benchmarks, rerank, index repair. |
| `tests/` | pytest suite (agent, MCP, injection guard, every `markets/` module). |
| `run_host.sh` | How launchd starts the service on the host. |
| `Dockerfile`, `requirements*.txt`, `ty.toml`, `.github/workflows/` | Reference image, dependencies, type-check config, CI. |

## quant_api — REST API

All Java code is under `src/main/java/org/example/quantapi/`.

| Path | Contents |
|---|---|
| `controller/` | Endpoints: auth, signals, positions and performance, holdings and transactions, market data, news, agent data (read-only, for quant_ai's tools), scripts, health; `ApiExceptionHandler`. |
| `service/` | Holdings (derived from the transaction log), portfolio, quotes, market data, news search; `service/signal/` publishes and consumes the daily-signal Kafka events. |
| `config/` | Security (Keycloak JWT, deny by default, read/write separation), Keycloak role mapping, Kafka. |
| `scheduler/` | Publishes the daily signals to Kafka on a schedule. |
| `model/`, `repository/`, `dto/`, `event/` | News document and repository, market DTOs, the signal event. |
| `src/main/resources/application.yml` | Ports, MongoDB URIs, Kafka topic. |
| `src/test/` | Holdings replay tests. |
| `Dockerfile`, `Dockerfile.runtime` | Full build, and the runtime-only image used under the VPN (jar built on the host). |

## quant_ui — dashboard

| Path | Contents |
|---|---|
| `src/pages/` | `Dashboard.tsx` (tabs), `Holdings.tsx` (holdings, daily action, indices), `Briefs.tsx` (market briefs), `Keywords.tsx` (weekly keyword review). |
| `src/components/` | `QuantModelPanel.tsx` (backtest vs SPY above the daily ranks; composes `PerformancePanel` and `SignalsPanel`), `PositionsPanel.tsx` (paper portfolio), task monitor and schedule, news list, login. |
| `src/components/markets/` | Holdings widgets: advisor, catalysts, global markets, indices, lot manager, price chart. |
| `src/api/` | Typed clients for quant_api and quant_ai. |
| `src/auth.ts` | Keycloak session, token refresh. |
| `nginx.conf`, `Dockerfile`, `Dockerfile.runtime` | Serving config; full build, and the runtime-only image (dist built on the host). |

## quant_docker — platform

| Path | Contents |
|---|---|
| `docker-compose.yml` | Every container, its pinned image tag, ports and environment. |
| `docker/airflow/` | Airflow image (with a vendored provider wheel). |
| `scripts/core.sh` | Starts the always-on core (login chain, Airflow metadata DB, Qdrant, MLflow) and stops the rest. |
| `scripts/host_proxy.py` | Host-side proxy bridge for pulling images under the VPN. |
| `README.md` | Platform overview and results. |
| `PROJECT_PLAN.md` | Roadmap and research log (Q, R, N series). |
| `docs/STRUCTURE.md` | This file. |

## quant_keycloak — identity

| Path | Contents |
|---|---|
| `quant-realm.json` | The `quant` realm: clients, roles, users. |
| `import-realm.sh` | Loads the environment file and imports the realm at startup. |
| `Dockerfile` | Keycloak image (PostgreSQL-backed). |

## Conventions

- **Backups** before an edit go to `/Volumes/Data4T/backups/<date>/<path>`, never next to the file.
- **Logs**: Airflow task logs are kept 30 days; scheduler stdout/stderr are trimmed in place.
- **Images** under the VPN are built from host artefacts with `Dockerfile.runtime` and tagged
  with the commit CI would tag, so the CI pull request that follows is a no-op.
