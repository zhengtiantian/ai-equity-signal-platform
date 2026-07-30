# Quant Data Project Plan

## Goal
Build a research-ready, then production-ready, mid-frequency stock prediction system for holding periods of:

- 1 week
- 2-4 weeks
- 2-3 months

The immediate objective is not live trading. The immediate objective is:

- reliable data pipelines
- clean research datasets
- factor validation
- backtesting
- model-ready feature tables

## Current Status

What already exists:

- historical and incremental news collection
- stock daily price collection
- company-match cleaning pipeline for news
- cleaned matched-news collection:
  - `news_articles_company_matched_v1`
- daily feature build pipeline
- cleaned feature collection:
  - `daily_symbol_features_company_matched_v1`
- first-pass single-factor backtest script

What is still missing:

- benchmark-relative labels and evaluation
- stronger research-quality filtering layer
- richer factor library
- grouped / long-short backtests
- model training pipeline
- portfolio construction layer
- production signal generation layer

## System Scope

The system should support:

- company/news relevance filtering
- daily feature generation
- mid-horizon return prediction
- factor and model research
- portfolio simulation
- scheduled data refresh
- production deployment later

## Required Data

### 1. News Data
Already partially done.

Needed:

- raw news store
- company-matched clean news store
- source metadata
- title
- body/content
- data quality tags
- company relevance result

Current collections:

- `news_articles`
- `news_articles_company_matched_v1`

### 2. Price Data
Needed:

- daily OHLCV
- adjusted close if possible
- volume
- trading date alignment

Current collection:

- `stock_prices_history`

### 3. Benchmark and Market Data
Still needed / should be added:

- SPY / QQQ / sector ETF daily prices
- benchmark forward returns
- optional factor benchmarks:
  - momentum
  - size
  - quality
  - volatility

### 4. Fundamental / Event Data
Recommended next:

- earnings dates
- EPS / revenue / guidance
- valuation metrics
- analyst estimate revision data if available
- corporate actions

### 5. Metadata
Needed:

- sector / industry
- market cap bucket
- symbol universe definition
- active/inactive date ranges

## Core Collections / Tables

### Raw Layer

- `news_articles`
- `stock_prices_history`

### Clean Layer

- `news_articles_company_matched_v1`

### Feature Layer

- `daily_symbol_features_company_matched_v1`

### Planned Next Collections

- `daily_symbol_features_research_v1`
  - optional refined feature table after additional research-quality filtering
- `backtest_results`
  - optional persistent experiment tracking
- `benchmark_prices`
  - benchmark ETF / index data
- `earnings_events`
  - earnings calendar / event layer

## Current Feature Set

Already generated in daily features:

- `article_count`
- `full_count`
- `title_only_count`
- `url_only_count`
- `full_ratio`
- `title_only_ratio`
- `avg_content_length`
- `max_content_length`
- `unique_url_count`
- `unique_source_count`
- `unique_platform_count`
- `extraction_failed_count`
- `timeout_fallback_count`
- `news_count_3d`
- `news_count_5d`
- `news_count_20d`
- `full_count_5d`
- `avg_full_ratio_5d`
- `news_burst_20d`
- `trade_date`
- `close`
- `future_ret_5d`
- `future_ret_20d`
- `future_ret_60d`

## Prediction Targets

The system should support multiple target definitions.

### Absolute Return Targets

- `future_ret_5d`
- `future_ret_20d`
- `future_ret_60d`

### Direction Targets

- `future_ret_5d > 0`
- `future_ret_20d > 0`
- `future_ret_60d > 0`

### Recommended Future Targets

- benchmark-relative return:
  - stock return minus SPY / QQQ / sector ETF return
- ranking target:
  - cross-sectional rank by future return

For this project, ranking and excess-return targets are likely more useful than pure up/down classification.

## Research Workflow

### Phase 1. Data Integrity

Done or mostly done:

- collect raw news
- clean company relevance
- build daily features
- align with price labels

Still needed:

- benchmark alignment
- event/fundamental enrichment

### Phase 2. Factor Research

Current next step.

Need to run:

- top/bottom bucket tests
- long-short tests
- top 3 / top 5 / top 10 portfolio comparisons
- stability by year
- stability by horizon

First candidate factors:

- `full_ratio`
- `news_burst_20d`
- `article_count`
- `unique_source_count`
- `avg_content_length`
- `extraction_failed_count` as a reverse-quality feature

### Phase 3. Multi-Factor Research

After single-factor validation:

- combine quality factors
- combine quantity + quality + recency factors
- compare weighted score vs single-factor selection

### Phase 4. Modeling

Only after factor validation.

Recommended order:

1. linear / logistic models
2. tree models:
   - LightGBM
   - XGBoost
3. ranking models

Do not start with large text models for price prediction.

### Phase 5. Portfolio Construction

Need explicit rules for:

- rebalance frequency
- top N holdings
- equal weight vs score weight
- sector cap
- single-name cap
- turnover limit
- transaction cost assumptions

### Phase 6. Production

Later phase:

- daily incremental collection
- feature refresh
- model scoring
- signal generation
- order routing
- monitoring
- logging
- retry / failure handling

## Research Principles

### 1. Prefer simple baselines first

Always test:

- single factor
- grouped returns
- naive top-N strategy

before training larger models.

### 2. Use safe date windows

Backtests should use:

- `trade_date >= 2015-12-04`

because current price data coverage starts there.

### 3. Use clean collection by default

Research should prefer:

- `news_articles_company_matched_v1`
- `daily_symbol_features_company_matched_v1`

instead of raw collections.

### 4. Keep raw data immutable

Do not delete raw source collections.

Use separate clean / derived layers.

## Engineering Plan

## Stage 1. Immediate Next Tasks

1. Extend first-pass backtest
- top / bottom buckets
- long-short
- top 3 / top 5 / top 10

2. Add benchmark comparison
- SPY / QQQ / sector baseline

3. Build quality factor basket
- combine `full_ratio`, `unique_source_count`, `avg_content_length`, etc.

4. Validate by horizon
- 5d
- 20d
- 60d

## Stage 2. Near-Term Data Expansion

Status: substantially complete.

### Completed items

- benchmark/index price collection:
  - done (`SPY`, `QQQ` daily prices, `benchmark_ret_5d/20d/60d`, `excess_ret_*`)
- earnings event Layer 1 (timing only):
  - done
  - features: `days_to_earnings`, `days_since_earnings`,
    `is_earnings_window_5d`, `is_post_earnings_window_20d`
- earnings event Layer 2 (surprise + richer timing):
  - done
  - features: `eps_estimate_last`, `reported_eps_last`, `surprise_pct_last`,
    `is_positive_surprise`, `is_negative_surprise`,
    `days_to_earnings_bucket`, `days_since_earnings_bucket`,
    `is_pre_earnings_10d`, `is_post_earnings_5d`, `is_post_earnings_10d`,
    `is_post_positive_surprise_20d`, `is_post_negative_surprise_20d`
  - result: Ridge `60d` IC improved from `0.073` to `0.121` (+66%)
- sector mapping: basic version integrated

### Next: earnings event Layer 3

Build on Layer 2 with deeper surprise structure and interaction features.

1. surprise magnitude buckets
   - split `surprise_pct_last` into ordinal buckets:
     - large miss (< -5%), small miss (-5% to 0), small beat (0 to +5%),
       large beat (> +5%)
   - rationale: the market reacts non-linearly to surprise size

2. news quality × earnings interaction features
   - `full_ratio_x_post_positive`: `full_ratio` × `is_post_positive_surprise_20d`
   - `quality_score_x_post_negative`: `quality_score` × `is_post_negative_surprise_20d`
   - rationale: a positive surprise with high-quality news coverage is a
     stronger combined signal than either alone

3. earnings recency decay
   - `earnings_recency_weight`: exponential decay of `days_since_earnings`
     (weight = exp(-days_since / 20))
   - rationale: the post-earnings drift effect weakens as time passes

4. rerun backtest and model after Layer 3
   - compare against the Layer 2 baseline (Ridge `60d` IC = `0.121`)

### Most important next step: universe expansion

The current universe is 14 symbols.
This is the single biggest constraint on signal reliability.

Why this matters:

- at 14 symbols, one bad year (e.g. 2022, 2024) can make the IC negative
  due to sampling noise alone
- cross-sectional ranking needs depth: `top 3 / top 5` out of 14 is not
  robust; `top 5 / top 10` out of 50-100 is meaningfully more stable
- the current signals may be real but cannot be confirmed at this universe size

Target: expand to 50-100 symbols.

What is required:

1. extend `stock_universe` collection with new symbols
   - suggested scope: S&P 500 tech/growth names, or a defined sector basket
   - keep sector distribution balanced

2. collect historical news for new symbols
   - extend GDELT / news collector coverage
   - run `company_match_rescore` on new articles

3. collect price history for new symbols
   - extend `stock_prices_history`

4. rebuild feature table
   - `FEATURE_REBUILD_ALL=true` after data is ready

5. rerun all backtests and models on expanded universe
   - compare single-factor IC at 50-symbol vs 14-symbol universe
   - a good signal should survive and become more stable

## Stage 3. Modeling

Status: first-pass baselines done.

Current baseline results (14-symbol universe):

- `Ridge` `60d` Rank IC: `0.121` / Top 5 excess return: `+6.58%`
- `HistGB` `60d` Rank IC: `0.118` / Top 5 excess return: `+6.32%`

Known issue: year-by-year variance is high.

- strong years: 2020 (IC = 0.35), 2023 (IC = 0.19), 2025 (IC = 0.24)
- weak years: 2022 (IC = -0.06), 2024 (IC = -0.04)
- likely cause: macro regime shifts (2022: rate hikes + war; 2024: election
  + rate pivot) break the news-quality thesis temporarily

Next modeling steps (do only after universe expansion):

1. year stability analysis
   - run `--group-by-year` on factor backtest with full feature set
   - identify which features drive the 2022/2024 failures
   - test whether regime-aware features (e.g. VIX level, market vol) help

2. simple Ridge + HistGB ensemble
   - average predictions from both models
   - rationale: the two models now have comparable IC and different error
     patterns; blending should reduce variance

3. sector-relative feature normalization
   - normalize `full_ratio`, `quality_score` within sector on each day
   - reduces bias from sectors that structurally attract more/less news

4. ranking model
   - convert to a pairwise ranking objective (LambdaRank or similar)
   - more directly aligned with the top-N portfolio construction goal

## Stage 3.5 Event-Driven Strategy Research

Goal: evolve the fixed-horizon model into a news event-driven strategy where
signals trigger dynamic entry, hold, and exit decisions rather than fixed
holding periods.

This stage must be completed before Stage 5 engineering work begins.

### 3.5.1 Article-level event tagging (LLM batch annotation) ✅ Done 2026-05-22

All 840,212 articles in `news_articles_company_matched_v2` tagged with:

- Pass A (Gemma): `llm_sentiment_a`, `llm_event_type_a`, `llm_signal_strength_a` — 100%
- Pass B (Qwen): `llm_sentiment_b`, `llm_event_type_b`, `llm_signal_strength_b` — 100%
- Dual-LLM merge: `llm_sentiment_final`, `llm_disagreement`, `llm_label_model_probs` — 100%
- Inter-model agreement rate 77.3%; mean sentiment +0.296 (overall positive bias)

Deliverable: `research/labeling/llm_enrich_articles.py`, `research/snorkel_label_merge.py`

Resume framing:
*"Enriched 845K financial news articles with two-pass LLM ensemble (Gemma +
Qwen), merged by a hand-written dual-LLM reconciler achieving 77.3% inter-model
agreement on sentiment, event type, and signal strength labels."*

### 3.5.2 Event-level daily features ✅ Done 2026-05-22

Rebuilt `daily_symbol_features_company_matched_v2` (134,642 rows, 100 symbols)
with full LLM sentiment feature coverage (100%):

| Feature | Coverage |
|---|---|
| `avg_sentiment_3d/5d` | 100% |
| `sentiment_shift_5d` | 99.6% |
| `high_signal_count_3d` | 100% |
| `negative_event_count_5d` | 100% |
| `disagreement_avg_5d` | 100% |
| `has_regulatory_risk_5d` | 100% |
| `earnings_beat_signal` / `earnings_miss_signal` | 100% |

Multi-horizon model results with LLM features (walk-forward, 100 symbols):

| Horizon | Ridge IC | Ensemble IC | Ensemble Top5 Excess Return |
|---|---|---|---|
| 20d | 0.036 | 0.031 | +1.83% |
| 45d | 0.044 | 0.043 | +4.38% |
| 60d | 0.056 | 0.059 | +6.59% |

IC increases monotonically with holding period; the 60d signal is strongest.

Deliverable: `research/features/daily_symbol_features.py`, `research/models/train_baseline_models.py`

### 3.5.3 Dynamic holding period backtest ✅ Done 2026-05-22

Event-driven framework results (100 symbols, 2018–2026):

Best config: `min_hold=20d`, `max_hold=60d`, `sentiment_shift_exit=-0.35`

| Metric | Event-Driven | Fixed 20d Baseline | Fixed 60d Baseline |
|---|---|---|---|
| Avg Hold | 13.7d | 20d | 60d |
| Excess Return | +1.40% | +1.22% | +3.80% |
| Win Rate | 52.7% | 58.0% | 63.1% |
| Trades | 390 | 2,060 | 2,020 |

Event-driven outperforms the fixed 20d baseline within 13.7 days (+1.40% vs +1.22%) with lower turnover.
Exit reasons: score_below_exit 69%, sentiment_reversal 17% (reasonable).
2022/2024 remain weak years (macroeconomic regime shifts).

Deliverable: `research/backtest/backtest_event_driven.py`

### 3.5.4 Multi-horizon label expansion ✅ Done 2026-05-22

Added to `daily_symbol_features_company_matched_v2`:
- `future_ret_10d/15d/30d/45d` — 87-88% coverage
- `excess_ret_10d/15d/30d/45d` — 87-88% coverage
- Also fixed `load_feature_frame` projection in `backtest_news_factor.py`

Deliverable: `research/features/daily_symbol_features.py`, `research/backtest/backtest_news_factor.py`

### 3.5.5 Fine-tune small model for sentiment scoring

After the two-pass LLM enrichment (3.5.1) completes, replace the slow LLM
inference pipeline with a purpose-fine-tuned small model. This eliminates the
need to keep Gemma + Qwen + a judge model running and reduces inference from
days to minutes.

**Training data**

Use articles where Pass A (Gemma) and Pass B (Qwen) agree as high-confidence
pseudo-labels:
- `llm_sentiment_a` and `llm_sentiment_b` same sign AND |diff| ≤ 0.2
- Expected: ~60-70% of 586K articles → ~350K+ clean training samples

**Model**

Fine-tune `ProsusAI/finbert` (110M params, already pre-trained on financial
text) with three output heads:
- sentiment: regression head, output -1.0 to +1.0
- event_type: 7-class softmax (earnings / product / MA / regulation / macro /
  competition / other)
- signal_strength: 3-class softmax (high / medium / low)

Training setup:
- LoRA or full fine-tune (BERT is small enough for full fine-tune)
- GPU: Windows machine (same as LM Studio)
- Estimated training time: 1-2 hours on 350K samples
- Framework: HuggingFace Transformers + PyTorch

**Inference speed after fine-tuning**

| Setup | Speed |
|---|---|
| Current LLM (Gemma via LM Studio) | ~3.9 art/s |
| Fine-tuned FinBERT (GPU) | ~1000-2000 art/s |
| Fine-tuned FinBERT (CPU only) | ~200 art/s |

586K articles: current ~41h → fine-tuned ~5-10 min

**Deliverables**

- `research/finetune_sentiment.py` — training script
- `research/infer_sentiment.py` — batch inference on remaining articles
- benchmark report: fine-tuned vs LLM scores on held-out set

**Resume framing**

*"Fine-tuned FinBERT on 350K+ pseudo-labeled financial news articles
(distilled from Gemma + Qwen ensemble), achieving 200x inference speedup
while maintaining comparable sentiment, event classification, and signal
strength accuracy."*

### Execution order

1. 3.5.4 Multi-horizon labels ✅
2. 3.5.1 Article tagging ✅
3. 3.5.2 Event features ✅
4. 3.5.3 Dynamic backtest ✅
5. 3.5.5 Fine-tune small model — Pending development

---

## Stage 4. Production Readiness

1. schedule feature build from clean news
2. track model versions
3. persist experiment results
4. build daily signal job
5. add monitoring

## File / Module Roadmap

### Existing

- `research/features/daily_symbol_features.py`
- `research/company_match_rescore.py`
- `research/backtest/backtest_news_factor.py`
- `research/features/load_earnings_events.py`
- `research/load_benchmark_prices.py`
- `research/models/train_baseline_models.py`
- `collectors/news/gdelt/special_rules/slm_filter.py`
- `collectors/news/gdelt/special_rules/slm_skills.py`

### Suggested Next Files

- `research/backtest_year_stability.py`
  - year-by-year IC breakdown with the full feature set
- `research/build_interaction_features.py`
  - earnings × news quality interaction features (Layer 3)
- `research/expand_universe.py`
  - helper to onboard new symbols into stock_universe and trigger collection

## Recommended Success Criteria

The project should be considered healthy if:

- clean company-matched news can be built reproducibly
- feature table refresh is stable
- at least one factor shows persistent positive excess return
- results are stable across multiple years
- simple baselines are competitive before modeling

## Current Practical Recommendation

Do next (in priority order, updated 2026-06-20):

1. **H.1 Backtest with transaction costs + liquidity filter** (2 days) — current Sharpe 0.70-0.84 is pre-cost; quantitative interviews always ask this, highest ROI
2. ~~**Stage 7 validation**~~ ✅ **Done** — Airflow now runs the full DAG set from a host `launchd` scheduler (containers cannot reach the host LLM under VPN), and the Kafka producer/consumer path was verified end to end after fixing a deserializer mismatch that had the consumer stuck in a poison-pill retry loop. Signals publish and are consumed with zero lag.
3. **E.7 README + architecture diagram** (1 day) — required for all interviews, currently missing, fastest result
4. **H.2.2 Dynamic factor weights** (regime-aware) — regime_mult base multiplier already exists; needs extension to auto-switch factor weight sets in volatile market
5. **H.3.2/H.3.3 Paper trading improvements** — position tracking and exit triggers already exist; missing OOS IC monitoring and -5% stop-loss rule
6. **Stage 3.5.5 FinBERT fine-tuning** — train on Gemma+Qwen consensus labels to replace LLM inference pipeline

Completed:

- universe expansion to 100 symbols ✅
- year stability analysis ✅
- earnings Layer 1 / 2 / 3 ✅
- Ridge + LightGBM + Ensemble baseline (60d IC = 0.10, Top5 = +6.7%) ✅
- Stage 3.5.1 LLM article tagging (845K articles, Gemma + Qwen + dual-LLM merge) ✅
- Stage 3.5.2 event-level daily features (134K rows, 100% LLM coverage) ✅
- Stage 3.5.3 event-driven backtest (min20d, +1.40% vs fixed 20d +1.22%) ✅
- Stage 3.5.4 multi-horizon labels (10/15/30/45/60d) ✅
- **D.1/D.2/D.4/D.7/D.8 research layer extensions all completed** (2026-06-16), D.3/D.5/D.6 skipped ✅
- **C.1-C.7, C.9 all completed (baseline versions)** (daily signal automation + UI + position tracking + exit alerts + risk metrics + data quality checks + factor analysis report, 2026-06-16~20) ✅
- **H.2.1 regime multiplier baseline** (score_daily_signals.py integrated macro_risk_on / macro_vix_pctile_252d to adjust signal strength) ✅
- Ops: removed duplicate launchd scheduler job to prevent all collection tasks from running twice daily ✅

Do not do next:

- live trading automation (live trading is still H.1-H.5 fully complete + 3-6 months of paper trading away from being truly usable)
- Stage 5 engineering before Stage 7 validation is complete

## Notes

The clean matched-news dataset is research-usable at the current scale.

The two-layer earnings feature set has produced a meaningful model
improvement (Ridge `60d` IC: `0.073` → `0.121`).

Signal IC at 60d = 0.059 on the 100-symbol universe is more credible than the 0.121 at 14 symbols (a larger universe dilutes overfitting). The weak 2022/2024 years are driven by macroeconomic regime shifts; the signal itself is credible.

---

# Interview Roadmap

## A. Data Engineer Interview Roadmap

### Currently Available (can discuss directly)
- MongoDB 845K+ articles + 675M GKG inverted index (large-scale document storage + full-text search)
- Python ETL pipeline: news collection → company matching → feature build (multiple data sources, incremental/full load)
- LLM batch inference pipeline (845K articles, two passes + dual-LLM merge)
- Docker Compose multi-service orchestration (MongoDB / MySQL / Kafka / Airflow / MLflow / Qdrant)
- Airflow DAG definitions (DAG structure, task dependencies, SLA)

### Critical Gaps — Must Fill (will be asked in interviews)

| What is missing | Why it matters | Stage | Effort |
|---|---|---|---|
| Kafka has no actual producer/consumer | DE must-ask; "deployed but unused" is unconvincing | Stage 7 / 5.1.1 | 3 days |
| Airflow DAG has not actually run end-to-end | "wrote a DAG" ≠ "it ran" | Stage 7 | 1 week |
| MLflow has no actual recorded runs | Can use the tool but has no output; can't answer interview questions about run results | Stage 7 / 5.2.3 | 1 day |
| No ETL unit tests | DE interviews always ask how pipeline reliability is guaranteed | New | 3 days |
| No data quality checks | Standard for production-grade pipelines; absence raises reliability doubts | New | 2 days |
| No idempotency design doc | DE must-know: will re-running the pipeline produce duplicates? | New (add doc) | 1 day |

### Bonus Items — Stronger with, not required to interview

| Item | Value | Stage | Effort |
|---|---|---|---|
| Flink streaming pipeline | High-demand DE skill at large companies, most differentiating | 5.2.2 | 2 weeks |
| dbt data lineage | Data modeling best practice, common in FinTech DE | 5.2.4 | 1 week |
| Prometheus + Grafana monitoring | Observability, also useful for SRE interviews | 5.4 | 3 days |
| Schema Registry (Kafka) | Avro schema evolution, large-scale data governance | 5.1.1 | 2 days |
| CI/CD for data pipeline | GitHub Actions running tests + lint | New | 2 days |
| Data lineage diagram | Which tables depend on which source; can use OpenLineage | New | 3 days |

### Complete DE interview story (after filling gaps)
*"Built a financial news processing system covering 100 stocks: established full-text index on GDELT raw data (675M records); Python ETL cleaned and matched 845K articles with idempotency design and data quality checks; Airflow scheduled 5 DAGs for daily incremental updates; Kafka publishes daily trading signals (complete producer/consumer pipeline); MLflow tracked 100+ model experiments; entire system deployable with a single Docker Compose command."*

---

## B. FinTech / Quantitative Finance Interview Roadmap

### Currently Available (can discuss directly)
- Walk-forward validation (not backtest overfitting), IC=0.059 (60d), 100 symbol universe
- Multi-factor model: news quality + momentum + earnings events + LLM sentiment
- Event-driven backtest framework (min_hold=20d, +1.40% excess return, outperforming fixed holding baseline)
- LLM dual-model ensemble labeling (Gemma + Qwen + dual-LLM merge, 77.3% agreement rate)
- 845K articles with three-dimensional labels: sentiment / event type / signal strength

### Critical Gaps — Must Fill (quantitative interview essentials)

| What is missing | Why it matters | Effort |
|---|---|---|
| Sharpe ratio / max drawdown / Sortino | Must-ask for quant roles; no numbers = incomplete strategy | 2 days |
| Turnover + transaction cost model (0.05% assumption) | Is the strategy still profitable after costs? | 1 day |
| Annualized return vs SPY buy-and-hold comparison | Does the strategy beat passive holding? | 1 day |
| Factor IC decay curve (autocorrelation) | How many days until the signal expires, determines rebalance frequency | 1 day |
| Information Ratio (IC / std(IC)) | Signal stability; IC=0.059 is usable but IR must be shown | 0.5 days |
| Long-short portfolio (not just Top-N) | Standard for quant funds; long-only = incomplete | 3 days |
| Factor correlation matrix (VIF / redundancy check) | Avoid multicollinearity, model interpretability | 1 day |
| Year-by-year Sharpe + drawdown chart | Quantify risk in weak years (2022/2024) | 1 day |

### Bonus Items — Stronger with

| Item | Value | Stage | Effort |
|---|---|---|---|
| FinBERT fine-tuning (200x inference speedup) | AI+Finance crossover, unique highlight | 3.5.5 | 1 week |
| Factor attribution analysis (SHAP feature importance) | Interpretability, can demo live in interview | New | 1 day |
| Beta neutralization / market-neutral portfolio | Institutional quant standard | New | 2 days |
| Volatility-weighted position sizing (non-equal weight) | More sophisticated portfolio construction than equal weight | New | 1 day |
| Liquidity filter (market cap threshold) | Avoid small-cap slippage, real-world executability | New | 0.5 days |
| RAG news semantic search | "Semantic search + finance" highlight | 5.3.1 | 1 week |
| Multi-agent research assistant | AI engineering depth showcase | 5.3.2 | 2 weeks |
| Paper trading live verification record | Out-of-sample real-world performance, most convincing in interviews | C.6 | Ongoing |

### Complete quantitative interview story (after filling gaps)
*"Built a news-driven multi-factor model on a 100-stock tech universe: 845K articles labeled by Gemma+Qwen dual-model LLM ensemble (77.3% agreement); walk-forward validation 60d Rank IC=0.059, Information Ratio=X.X; event-driven holding framework achieved +1.40% excess return in an average of 13.7 days (after transaction costs +X.X%), annualized Sharpe=X.X, max drawdown X%, long-short annualized excess X%."*

---

## C. Project Productionization Roadmap (News Events → Buy/Sell/Hold Decisions)

### Minimum Viable Loop (do first)

#### C.1 Daily signal generation automation ✅ Done (integrated with launchd scheduler, not Airflow)
- `score_daily_signals.py` integrated into `scheduler/task.py`, runs automatically at 08:30 daily
  (`daily_symbol_features` 08:00 → `score_daily_signals` 08:30 → `track_positions` 08:40)
- Scores 100 stocks, writes results to `daily_signals` collection
- Fields: `symbol`, `trade_date`, `composite_score`, `signal_rank`, `signal_type` (LONG/NEUTRAL),
  `regime_mult`, and D-series context fields (`ah_gap`, `analyst_buy_ratio_chg_1m`,
  `inst_holding_pct_chg`, `retail_sent_score`, `macro_risk_on`, `macro_vix`, etc.)
- Note: still using launchd, not Airflow (Stage 7 / 5.2.1 Airflow migration still pending)

#### C.2 Risk metrics ✅ Done (`research/backtest/backtest_portfolio.py`)
- Available: Sharpe ratio (annualized, 4% risk-free rate), max drawdown, win rate, annualized return vs SPY
- 2026-06-16 validation results (full history 2015-2026, reusing `score_daily_signals.compute_score`):
  - 20d holding: Sharpe 0.84, annualized 25.8%, vs SPY Sharpe 0.54/12.1%
  - 60d holding: Sharpe 0.70, annualized 24.3%, vs SPY Sharpe 0.46/11.6%
- Still needed: Sortino ratio, turnover / transaction cost assumptions (see H.1; costs not yet deducted, numbers are optimistic)

#### C.3 Signal UI page ✅ Done (`SignalsPanel.tsx`)
- Displays all signals for the day, sorted by `signal_rank`, LONG/NEUTRAL labels color-coded
- Risk-on/Risk-off badge at top showing `regime_mult` (macro multiplier)
- Columns: Score / Quality / News burst / Earnings / AH Gap / Analyst Δ1m / Inst Δ
- 2026-06-16: added 3 D-series columns + regime badge (`quant_api` DailySignalEvent fields expanded in sync)
- Still needed: separate grouped display for watch list / avoid list (currently a single sorted table)

### Advanced (second priority)

#### C.4 Position tracking ✅ Done (`research/signals/track_positions.py`)
- `positions` collection records simulated holdings: `symbol`, `entry_date`, `entry_price`, `entry_score`,
  `entry_rank`, `days_held`, `current_return`/`exit_return`, `exit_trigger`
- Idempotent: each run fully rebuilds state from `daily_signals` + `stock_prices_history`
- `PositionsPanel.tsx` displays current position status + unrealized P&L (already in quant_ui)
- 2026-06-20 validation: 19 positions (16 open/3 closed), PANW +62.6% / LRCX +50.5% leading

#### C.5 Exit alerts ✅ Done + extended 2026-06-16
- Existing triggers: `max_hold` (60 days), `score_below_exit`, `sentiment_reversal`, `earnings_miss`
- **Two new D-series triggers added**: `analyst_downgrade` (`analyst_buy_ratio_chg_1m` < -10%), `inst_outflow` (`inst_holding_pct_chg` < -1% QoQ)
- Alerts written to `alerts` collection; UI red dot / email push still pending (currently script print + collection query only)

#### C.6 Paper trading record ✅ Baseline done (i.e. C.4 `track_positions.py`)
- Daily `daily_signals` Top-N used to simulate entries; unrealized P&L updated daily with real prices
- Total running days are still short; 3-6 month out-of-sample performance is accumulating (ongoing task, not one-time development)

#### C.7 ETL data quality checks ✅ Baseline done (`research/quality/data_quality_check.py`)
- Existing checks: news volume, price freshness, feature freshness, key field NULL rate thresholds
  (`quality_score`/`full_ratio`/`close`/`past_ret_20d`), signal freshness
- Integrated with scheduler to auto-run at 09:00 daily (`ENABLE_DATA_QUALITY_JOB`)
- Still needed: model training IC anomaly detection (2-sigma alert), write results to `quant_api` instead of script output only

#### C.8 ETL unit tests ✅ Done (2026-07-15)
- 90 tests, 0 failures — `pytest tests/ -q` green
- `test_feature_build.py` (29): news aggregation, LLM sentiment, quality score, date helpers
- `test_regime_scoring.py` (16): H.2 `classify_regime` (all 4 regimes + edge cases), `compute_score`
  (output columns, conviction multipliers, rank ordering), `_safe_float`
- `test_positions.py` (17): H.3 `_stop_pct` (floor/cap/passthrough), `compute_daily_vols` (≥22 bar
  requirement, constant-price zero-vol, multi-symbol), `_spearman_ic`, `build_positions` stop-loss trigger
- `test_earnings_regime.py` (28): `attach_earnings_event_features` (empty inputs, surprise_pct, beat/miss
  signals, no-symbol-overlap), `compute_regime_features` (all output columns, calm/high-VIX/SPY-trend)
- Coverage: `score_daily_signals.py` 60%, `track_positions.py` 52%, `daily_symbol_features.py` 40%

#### C.9 Factor analysis report ✅ Done (`research/backtest/factor_analysis.py`)
- Implemented: IC decay table (multi-horizon), year-by-year IC breakdown, SHAP feature importance
  (including LLM vs traditional factor contribution split)
- Updated: long-short portfolio + year-by-year Sharpe/drawdown chart implemented in `factor_analysis.py` walk-forward section ✅
- Still needed (optional enhancement): factor correlation matrix (VIF redundancy check)

### Full productionization path (time estimates)

```
Stage 7 services running end-to-end (1 week)
  → C.2 risk metrics + C.9 factor report (3 days)  ← can discuss in interview immediately
  → C.8 ETL unit tests (3 days)                    ← proves reliability in DE interviews
  → C.7 data quality checks (2 days)               ← production-grade credibility
  → C.1 daily signal automation (3 days)           ← project starts "moving"
  → C.3 signal UI page (3 days)                    ← visualized decisions
  → C.4 position tracking (1 week)                 ← real decision support
  → C.5 exit alerts (3 days)                       ← loop closed
  → C.6 paper trading (ongoing)                    ← accumulate real-world performance
  → project productionized + interview-ready ✓
```

---

## D. Research Layer Extensions (improve model quality)

### D.1 Macro Regime features ✅ Done 2026-06-16
- VIX level/percentile, 10Y interest rate, US dollar index, SPY 20-day trend
- Fields: `macro_vix`, `macro_vix_pctile_252d`, `macro_vix_change_5d`, `macro_tnx`,
  `macro_tnx_change_20d`, `macro_spy_ret_20d`, `macro_spy_above_200ma`,
  `macro_risk_on`, `macro_is_high_vol`, `macro_dxy_change_20d`
- In 2026 holdout, `macro_tnx` is the #2 ranked feature in LightGBM feature importance
- `macro_risk_on`/`macro_vix_pctile_252d` integrated into `score_daily_signals.py` as
  regime multiplier (risk-on ×1.20, high VIX ×0.85) — H.2.1 baseline implemented
- Deliverable: `collectors/macro/collector.py`

### D.2 Alternative Data — Retail Sentiment ✅ Done 2026-06-16
- Integrated StockTwits public API (no Reddit developer approval required, bypassing the registration rejection issue)
- New factors: `retail_msg_count`, `retail_bull_ratio`, `retail_sent_score`,
  `retail_sentiment_divergence` (= retail_sent_score − avg_sentiment_3d)
- Coverage starts from 2025-12 only, fill rate low (~3-4%), requires ongoing accumulation;
  2026-06-20 review: IC reversed from +0.09 to -0.10 (N still small, no conclusion yet, **weights not adjusted**)
- Deliverable: `collectors/retail/collector.py`

### D.3 Earnings filing text mining (10-K/10-Q) — Skipped
- Reason: requires LLM to parse large volumes of long text; engineering effort is high, lower priority than other D items
- Status: [ ] Not developing for now

### D.4 Analyst rating change factor ✅ Done 2026-06-16
- Finnhub `/api/v1/stock/recommendation`, accessed via `urllib` (under VPN, `requests`/`curl_cffi` failed; only `urllib.request.urlopen` works)
- New factors: `analyst_buy_ratio`, `analyst_sell_ratio`, `analyst_consensus_score`,
  `analyst_buy_ratio_chg_1m`
- Cross-sectional IC: `analyst_buy_ratio_chg_1m` 5d=+0.155 / 20d=+0.151, one of the cleanest signals in the D series
- Deliverable: `collectors/analyst/collector.py`

### D.5 Options market signals — Skipped
- Reason: CBOE PCR free historical data only goes back to 2019, cannot cover recent backtest window
- Status: [ ] Not developing for now

### D.6 Short Interest (short squeeze pressure) — Skipped
- Reason: FINRA website returns bot protection page under VPN, unable to scrape
- Status: [ ] Not developing for now

### D.7 Institutional holdings change (13F) ✅ Done 2026-06-16
- `edgartools`, tracking Vanguard/StateStreet/Fidelity holdings for the most recent 2 quarters
- New factors: `inst_holding_pct` (aggregate holding percentage across institutions), `inst_holding_pct_chg` (QoQ,
  computed separately for each institution's most recent two periods then averaged, avoiding misalignment from different institutions' disclosure cycles)
- Cross-sectional IC: `inst_holding_pct_chg` 60d=**+0.198**, strongest single factor in the D series
- In 2026 holdout, the single feature contributing most to LightGBM regression IC (IC=+0.337)
- Integrated as `inst_outflow` exit trigger in `track_positions.py`
- Deliverable: `collectors/inst_13f/collector.py`

### D.8 Pre-market / after-hours price signals ✅ Done 2026-06-16
- yfinance 1-minute data (`prepost=True`), chunked into 7-day windows to avoid "8-day limit" error
- New factors: `pm_gap`, `ah_gap`, `ah_volume_ratio` (`pm_volume_ratio` removed — yfinance pre-market volume field is always 0, cannot compute a valid ratio)
- Cross-sectional IC: `ah_gap` 5d=**+0.227**, the strongest short-term signal in the D series
- yfinance 1-minute history capped at 30 days; scheduler accumulates daily — as of 2026-06-20 there are 23 trading days
- Deliverable: `collectors/premarket/collector.py`

### D-series end-to-end integration (2026-06-16 ~ 2026-06-20)
All completed items are wired through the full pipeline:
`daily_symbol_features.py` (features) → `train_baseline_models.py` / `backtest_news_factor.py`
(training; 60d target significantly outperforms 20d; 2026 holdout IC=0.73 vs historical baseline 0.04-0.05) →
`score_daily_signals.py` (scoring weights + macro regime multiplier) → `track_positions.py`
(`analyst_downgrade`/`inst_outflow` new exit triggers) → `quant_api`/`quant_ui`
(DailySignalEvent expanded with 8 new D-series fields; SignalsPanel shows regime badge + 3 new columns).

`backtest_portfolio.py` full-history backtest (2015-2026, reusing `score_daily_signals.compute_score`):
60d Sharpe=0.70, 20d Sharpe=0.84, both outperforming SPY (Sharpe 0.46-0.54) — but these results are primarily driven by the existing LLM/earnings factors; D-series data windows are short, so their contribution to historical backtest is not yet fully reflected; true incremental impact requires attribution analysis after data accumulates.

**Ops fix**: On 2026-06-20 discovered `com.quant.scheduler` (old) and `com.quant.pipeline-scheduler`
(new) were both running as launchd jobs, causing all collection tasks to execute twice daily. The old job has been unloaded (plist moved to `~/Quant_trade_backups/`).

---

## E. Engineering Layer Completion (interview bonus / project completeness)

### E.1 REST API documentation (Swagger / OpenAPI)
- Add Swagger annotations to all `quant_api` endpoints; generate interactive documentation
- Open `/swagger-ui.html` during interview demo to directly showcase API design
- Status: [ ] Pending development (1 day)

### E.2 CI/CD Pipeline (GitHub Actions)
- Auto-run on every push: Python lint (ruff) + unit tests + Docker build
- main branch protection: PRs must pass CI before merging
- Status: [ ] Pending development (2 days)

### E.3 Docker image version management
- Tag quant_api / quant_ui / quant_data images with git commit hash
- docker-compose pins versions, no `latest` tag
- Support one-command rollback to previous stable version
- Status: [ ] Pending development (1 day)

### E.4 K8s deployment configuration
- Convert docker-compose to Kubernetes YAML (Deployment / Service / ConfigMap)
- No need to actually run K8s; having the config files is enough for interviews
- Bonus for DE / Platform engineer interviews at large companies
- Status: [ ] Pending development (3 days)

### E.5 Data lineage diagram (OpenLineage)
- Use OpenLineage or hand-written lineage JSON to describe:
  `news_articles` → `company_match` → `news_articles_company_matched_v2`
  → `daily_symbol_features_company_matched_v2` → `daily_signals`
- Visualize data flow; a common DE interview topic
- Status: [ ] Pending development (2 days)

### E.6 WebSocket real-time push
- When a position triggers an exit condition, UI pops an alert in real time (no page refresh needed)
- Spring Boot WebSocket + quant_ui frontend subscribe
- Corresponds to the WebSocket infrastructure for 5.1.2 Backtest orchestration API
- Status: [ ] Pending development

### E.7 Project README + architecture diagram
- Write a complete README: project background, architecture diagram, quick start, key metrics
- Architecture diagram: data flow → feature engineering → model → signals → UI
- Required before any interview; first impression on GitHub
- Status: [ ] Pending development (1 day)

### E.9 UI Intraday Price Chart

**Goal**: Add a price chart to the signal/position panels in `quant_ui` so users can see intraday price action alongside signal scores.

**Design:**
- Use **TradingView Lightweight Charts** (open-source, MIT license, no CDN dependency — bundle inline)
- Data source: Alpaca historical bars API (intraday 1h, up to 2 years; no need to store hourly data in own MongoDB)
- Display: overlay signal entry date (green arrow) + stop-loss level (red dashed line) on the price chart
- Placement: expandable panel below each position row in `PositionsPanel.tsx`; also available in `SignalsPanel.tsx` on click

**What is NOT needed:**
- Storing hourly bars in MongoDB — Alpaca API serves them on-demand
- Any change to the Python pipeline — purely a frontend + quant_api thin adapter
- Historical hourly data for backtesting — current strategy is 5–60d, intraday features not used

**Development steps:**
1. `quant_api`: add `GET /api/v1/prices/{symbol}/intraday?period=3m&interval=1h` — calls Alpaca bars API, returns OHLC JSON (0.5 day)
2. `quant_ui`: install `lightweight-charts` npm package; create `PriceChart.tsx` component (1 day)
3. Wire chart into `PositionsPanel.tsx` (expandable on row click) + `SignalsPanel.tsx` (1 day)
4. Overlay: entry date vertical line, stop-loss horizontal line, signal score color band (0.5 day)

**Note on automated trading**: For live order execution, intraday stop-loss monitoring uses Alpaca WebSocket real-time quotes — not stored hourly bars. Historical hourly bars are only needed if the strategy itself uses intraday features (it does not currently).

- Status: [ ] Pending (3 days)

---

### E.10 Inference Node Health Check + Failover

**Context**: LLM/SLM inference runs on a dedicated GPU node (Windows, Ryzen 9800X + RTX 5090 + 96G, LM Studio at `192.168.31.226:1234`); the Mac pipeline calls it via `SLM_API_URL`. A local fallback LM Studio exists on the Mac (`127.0.0.1:1234`) but switching is manual today. The SLM filter already degrades to pass-through when no endpoint responds — failover should try the local node *before* giving up.

**Goal**: automatic endpoint selection so labeling jobs keep running when the GPU node is offline.

```
resolve_slm_endpoint():
    for url in [SLM_API_URL_PRIMARY (5090 node), SLM_API_URL_FALLBACK (local)]:
        GET {url}/models with 2s timeout → healthy? return url
    return None → existing pass-through degradation
```

**Implementation**:
1. Shared helper in `slm_filter.py` / `llm_enrich_articles.py`: probe on startup + re-probe on connection error (cached 60s)
2. Log which endpoint served each batch (throughput differs ~5×; needed for run-time estimates)
3. Optional: Slack alert on failover so silent GPU-node outages are visible

**Interview value**: turns the multi-node setup into a defensible story — "heterogeneous GPU offload with health-checked failover and graceful degradation".

- Status: [ ] Pending (1 day)

---

## F. AI Engineering Layer (AI Engineer / MLE interview bonus)

### F.1 Prompt Engineering evaluation framework
- Compare labeling accuracy of different prompt templates (use 100 manually-annotated articles as ground truth)
- Output evaluation report: precision / recall / confusion matrix (event_type classification)
- Proves the LLM pipeline is "validated", not just run arbitrarily
- Status: [ ] Pending development (2 days)

### F.2 Vector database news semantic search (RAG)

> **Superseded by R.1–R.4.** This entry claimed "Qdrant already deployed" — that was never
> true; there is no `qdrant` service in `docker-compose.yml`. The scope also stopped at a
> search box, which is the part that does not answer the depth question. Kept for the UI
> surface only; the retrieval work itself now lives in the R-series.

- Endpoint: `/search?q=NVIDIA earnings beat Q3` → relevant articles + LLM summary
- Search box in quant_ui, served by the R.2 hybrid retriever
- Status: [ ] Pending — retrieval moved to R.1/R.2/R.3; this is the UI layer on top (1 day, after R.2)

### F.3 Model interpretability report (SHAP)
- Run SHAP analysis on LightGBM model
- Output: factor contribution ranking, per-stock prediction explanation (why AAPL gets a high score)
- Interview demo killer: not just "IC=0.059" but also "driven primarily by avg_sentiment_5d and earnings_recency_weight"
- Status: [ ] Pending development (1 day)

### F.4 Multi-Agent research assistant (LangGraph)
Extend the existing `quant_langchain` container from LLMChain to a LangGraph stateful agent graph.

**Agent architecture (4-node graph):**
```
User input: "Analyze recent NVDA news and give a trading recommendation"
    ↓
data_agent      → calls quant_api to fetch news + price + sentiment factors
    ↓
analysis_agent  → reads IC ranking + sentiment distribution, LLM interprets recent events
    ↓
strategy_agent  → generates entry/exit rules (combining LLM scores + quantitative signals)
    ↓
risk_agent      → position sizing, stop-loss conditions, final output: position recommendation JSON
```

**Current state (existing foundation):**
- `quant_langchain/main.py`: placeholder endpoints `/api/workflow/generate-spec` and `/api/workflow/generate-tasks` already exist, but only do prompt → JSON with no execution capability
- `quant_api/StrategyService.java`: already calls langchain-agent; can directly serve as tools server
- Missing: LangGraph agent loop, tool registration, state persistence

**Development steps:**
1. Install langgraph, refactor `quant_langchain/main.py` (2 days)
2. Register tools: `search_news(symbol, days)` → calls quant_api; `get_features(symbol)` → MongoDB; `run_backtest(rules)` → Python
3. Implement 4-node graph + state passing (2 days)
4. Add ReAct loop: analysis_agent can decide whether it needs more data (1 day)
5. Integrate Qdrant RAG (after F.2 is done): data_agent can semantically search relevant news (1 day)

**Demo flow (for interviews):**
- Input: "Has AAPL had any negative news in the last 30 days? Should I hold a position now?"
- data_agent fetches news + sentiment distribution
- analysis_agent finds `avg_sentiment_5d = -0.3`, identifies regulatory risk event
- strategy_agent recommends "wait and watch; build position after sentiment recovers"
- risk_agent adds: if holding, stop-loss at -3%, max position size 5%

**Interview value:** covers ReAct reasoning + tool use + state graph — core competency for MLE / AI Engineer roles
- Status: [ ] Pending development (2 weeks)

### F.6 Upgrade rule_validator to a real Agent (ReAct loop)
**Current state:** `quant_data/tools/rule_validator_agent.py` has a prototype of "LLM judges → tool call → re-judges", but the sequence is hardcoded with no reasoning loop.

**Upgrade direction:**
- Validation failure → agent autonomously decides: fetch more articles / modify prompt / mark as ambiguous
- When handling ambiguous names from `ambiguous_names.py`, agent proactively searches for company background to decide
- Change from "pipeline" to "ReAct agent with memory"

**Development steps:**
1. Rewrite `rule_validator_agent.py` with LangGraph; add tools: `fetch_article(url)`, `search_web(company)`, `label_ambiguous(name, reason)`
2. Agent decides on its own whether more evidence is needed, up to N steps
3. Output trace: which steps each rule validation went through and the final reasoning basis

- Status: [ ] Pending development (3 days)

### F.7 Airflow adaptive scheduling Agent
**Current state:** All 4 DAGs in `airflow/dags/` are static time-triggered, with no adaptive capability.

**Upgrade direction:**
- Add `quality_monitor_dag`: after the pipeline runs each day, agent analyzes:
  - Is news volume abnormally low? (data source down?)
  - Is LLM label disagreement rate increasing? (model degradation?)
  - Has signal IC been declining for 5 consecutive days? (needs retraining?)
- Agent outputs decision: trigger re-run / switch to stronger model / send alert / auto-submit retraining job

**Development steps:**
1. Create `quality_monitor_dag.py`; BranchPythonOperator decides based on metrics (1 day)
2. Add LLM decision node: send anomaly metric summary to LLM, output recommended action (1 day)
3. Integrate Kafka: agent decision → publish to topic → downstream consumes (1 day)

- Status: [ ] Pending development (3 days)

### F.8 LLM annotation active learning Agent (disagreement sample handling)
**Current state:** Gemma + Qwen disagreement rate is 22.7%; merged blindly by the dual-LLM reconciler (`merge_ab_labels.py`).

**Upgrade direction:**
- For high-uncertainty samples where label_model_probs < 0.7, agent actively intervenes:
  - Sends the original text + both model outputs together to a stronger LLM (Qwen3-27B / GPT-4o)
  - Agent produces the final label + explanation ("model A mislabeled because the article is about earnings, not a company event")
  - Added as hard negative examples to the FinBERT training set
- Expected: disagreement sample accuracy improved from ~60% to ~85%

**Development steps:**
1. Filter samples where `llm_disagreement=1 AND llm_label_model_probs < 0.7` (~190K records)
2. Write `active_learning_agent.py`: batch-submit to stronger model, parse output, write back to MongoDB
3. Update `llm_sentiment_final` field, rerun feature build
4. Compare IC before and after

- Status: [ ] Pending development (4 days)

### F.5 FinBERT fine-tuning (3.5.5)
- Train on Gemma+Qwen consensus labels (~650K samples)
- Three heads: sentiment regression + event_type 7-class + signal_strength 3-class
- Inference speed: ~3.9 art/s → ~1000+ art/s (200x speedup)
- Status: [ ] Pending development (1-2 weeks)

### F.9 Rule Optimization Agent (Iterative Self-Improving Loop)

**Goal**: After news collection, automatically evaluate collection quality by stratified sampling across years, computing precision/recall with an LLM judge, diagnosing failure modes, modifying rules, and repeating — converging on optimal rules without manual tuning.

This directly addresses the known SLM Phase 3 "incidental mention" false positive problem (Morgan Stanley survey cited in Apple articles, da Vinci art in ISRG articles, etc.) and eliminates the need for manual rule maintenance.

**Agent architecture (4-phase loop):**

```
Round N:
  ┌─ Sampler    → stratified sample: 10 articles × 10 years × target symbols
  ├─ Evaluator  → LLM judge (Claude/GPT-4o) labels each: TP / FP / FN
  ├─ Diagnoser  → groups errors by failure type:
  │               - incidental mention FP
  │               - wrong company FP (similar name)
  │               - relevant article FN (missed match)
  │               - rule too aggressive (over-filtered)
  └─ Modifier   → proposes rule changes; applies them; logs diff

Repeat up to 10 rounds; stop when F1 improvement < 1% between rounds.
```

**What can be modified per round:**
| Rule layer | Modification type |
|---|---|
| SLM Phase 3 prompt (`slm_filter.py`) | Strengthen "primary subject" constraint; add incidental-mention examples |
| `ambiguous_names.py` entries | Add/remove disambiguation entries for specific symbols |
| Relevance threshold | Adjust score cutoff per symbol type (large-cap vs small-cap) |
| Special per-symbol rules | Add blocklist keywords that generate systematic FPs |

**Ground truth strategy:**
- Primary judge: Claude Opus (silver standard; low cost per article, fully automated)
- Escalation: articles where judge confidence < 0.7 → flag for human review
- Batch size: 100 articles per round (10/year × 10 years); full evaluation costs ~$0.50/round

**Sampling strategy:**
```python
# Stratified sample: balanced across years and symbols
years = range(2015, 2025)          # 10 years
articles_per_year = 10             # 10 per year = 100 total per round
symbols_sampled = 5                # rotate symbols each round to avoid overfitting
# → 100 articles judged per round × 10 rounds = 1000 total labels
```

**Output per round:**
- Accuracy report: precision / recall / F1, broken down by year and by error type
- Rule diff: unified diff of what changed vs previous round
- Convergence tracker: F1 trend across rounds (stop condition: ΔF1 < 1%)

**Stored in MongoDB:**
```json
{
  "round": 3,
  "timestamp": "2026-07-15T10:00:00Z",
  "metrics": { "precision": 0.87, "recall": 0.91, "f1": 0.89 },
  "error_breakdown": { "incidental_mention_fp": 6, "wrong_company_fp": 2, "fn_missed": 4 },
  "rules_changed": ["slm_filter.py prompt v3", "ambiguous_names: +MSFT_survey_blocklist"],
  "sample_ids": ["article_id_1", "..."]
}
```

**Development tasks:**
1. `tools/rule_optimizer_agent.py` — main agent loop (LangGraph or simple Python loop)
2. `tools/news_sampler.py` — stratified sampling from `news_articles_company_matched_v2`
3. `tools/llm_judge.py` — call Claude API, parse TP/FP/FN verdict + reason
4. `tools/rule_modifier.py` — apply proposed changes to SLM prompt / ambiguous_names.py, write diff to MongoDB
5. `tools/accuracy_reporter.py` — compute metrics, print round summary, decide continue/stop
6. Integrate into `scheduler/task.py` as a weekly or on-demand job

**Execution modes:**
- `--mode eval` (evaluation only; no rule changes) — runs before any deploy to get baseline
- `--mode optimize` (full loop; modifies rules) — run after adding new symbols or when FP rate spikes
- `--mode audit --round 3` (inspect a specific round's samples and verdicts)

**Interview framing:**
*"Built a self-improving news validation agent that iteratively samples historical articles across 10 years, evaluates relevance with an LLM judge, diagnoses failure modes (incidental mention FP, wrong-company FP, missed matches), and modifies SLM prompts and disambiguation rules — converging from F1=0.XX to F1=0.XX in 10 rounds."*

**Relates to:** F.6 (rule_validator ReAct), F.8 (active learning), project_slm_optimization (incidental mention FP)

- Status: 🟡 Developed, not yet tested (2026-07-13)

---

### F.10 Strategy Studio → Backtest Execution Pipeline

**Goal**: Close the loop on the existing Strategy Studio UI (quant_ui `StrategyStudio.tsx`). Currently the UI generates StrategySpec JSON + Tasks JSON + Strategy XML via LLM and saves them to the DB — but nothing executes them. This item wires the saved strategy into the existing Python backtest engine so users get real P&L results back in the UI.

**Current state:**
- `quant_ui/src/pages/StrategyStudio.tsx`: full prompt → spec → tasks → XML → save flow already works
- `quant_ai` (localhost:18000): generates StrategySpec/Tasks/XML via local LLM
- `quant_api/StrategyService.java`: `/api/v1/strategies/save` stores to MySQL
- **Missing**: a run-backtest endpoint that parses the saved strategy and routes to Python backtest

**Design:**

```
User clicks "Run Backtest" in Strategy Studio UI
    ↓
POST /api/v1/strategies/{id}/backtest  (quant_api)
    ↓
StrategyService.java parses StrategySpec JSON:
  - instruments (e.g. ["AAPL", "MSFT"])
  - entry_rule  (e.g. "rsi_14 < 30" or "avg_sentiment_5d > 0.3")
  - exit_rule   (e.g. "rsi_14 > 70" or "stop_loss: 0.05")
  - horizon_days, lookback_years
    ↓
Triggers Python subprocess or HTTP call:
  research/backtest/backtest_portfolio.py  (signal-based strategies)
  research/backtest/backtest_event_driven.py  (event-driven strategies)
    ↓
Returns to UI: Sharpe, annualized return, max drawdown, hit rate
```

**Development steps:**
1. **StrategySpec parser** (`research/strategy_runner.py`): read JSON spec, map `entry_rule` field to existing signal columns in `daily_symbol_features`; validate that required features exist (1 day)
2. **Backtest adapter**: wrap `backtest_portfolio.py` so it accepts a StrategySpec dict instead of hardcoded parameters; add `--spec-file` CLI flag (1 day)
3. **quant_api endpoint**: `POST /api/v1/strategies/{id}/backtest` → call Python subprocess, poll result, return metrics JSON (1 day)
4. **UI result panel**: add "Run Backtest" button + result card below Save Result in `StrategyStudio.tsx` showing Sharpe/return/drawdown (0.5 day)

**Scope constraint**: Only support strategies whose `entry_rule` maps to existing feature columns (avg_sentiment_5d, rsi, etc.) — not arbitrary code execution. This keeps scope tight while making the demo fully functional.

**Interview framing:**
*"Built a full natural-language → backtest pipeline: user describes a strategy in plain English, the local LLM (via LM Studio) generates a structured StrategySpec, which is then executed against 5 years of historical data using the existing walk-forward backtest engine, returning Sharpe / drawdown / hit rate directly in the UI."*

- Status: [ ] Pending (3-4 days)
  - `tools/llm_judge.py` — LLM judge (Claude API + local SLM fallback, TP/FP + fp_type + regex proposal)
  - `tools/rule_optimizer.py` — main loop (sample → judge → diagnose → propose → patch → repeat)
  - `collectors/news/gdelt/special_rules/ambiguous_names.py` — patch loader added (merges `tools/rule_optimizer_patches.json` at init)

---

### F.11 News Pre-filter SLM (Fast Relevance Triage)

**Goal**: Add a lightweight binary classifier before the expensive Gemma+Qwen dual-pass pipeline to discard obviously irrelevant GDELT articles early, reducing LLM inference load by ~70%.

**Design**: Fine-tune a tiny SLM (e.g. `distilbert-base-uncased`, 66M params) on the existing labeled set where both Gemma and Qwen agree (`llm_sentiment_final` non-null + `llm_disagreement=0`). Binary output: relevant / irrelevant. Articles classified as irrelevant skip the dual-LLM pass entirely.

**Expected impact**: ~70% of GDELT articles are low-quality noise; filtering these reduces dual-LLM cost without degrading labeled dataset quality.

- Status: [ ] Pending (3 days)

---

### F.12 Signal Explanation Generation (SLM → UI)

**Goal**: For each stock with a high signal score today, auto-generate a 2-sentence plain-English explanation of *why* — visible in the Signals UI panel.

**Example output**: *"NVDA scores 87/100 today. Institutional holdings increased 2.1% QoQ (strongest factor) and avg_sentiment_5d hit +0.42 following multiple positive data center coverage articles."*

**Implementation**: After `score_daily_signals.py` runs, pass top-N stocks' feature values to local SLM (Qwen 3.5 9B via LM Studio) with a prompt template → store explanation string in `daily_signals` MongoDB collection → `quant_api` exposes it → `SignalsPanel.tsx` renders inline.

- Status: [ ] Pending (2 days)

---

### F.13 Morning Briefing Agent (Daily Pre-market Summary)

**Goal**: Every trading day at 07:00 (before market open), auto-generate a short briefing for currently held positions: overnight news, regime status, any exit warnings.

**Output example**:
```
Morning Briefing — 2026-07-15 07:00

PANW (+62.6% unrealised) — No material news overnight. Regime: RISK_ON.
LRCX (+50.5%) — 2 articles mentioning inventory correction risk. Consider monitoring.
Regime: RISK_ON (macro_vix_pctile=0.22, macro_risk_on=1)
Exit alerts today: None
```

**Implementation**: `scheduler/task.py` new job at 07:00 → fetch held positions + overnight GDELT + regime → prompt local SLM → write to `daily_briefings` collection → push to UI + optional email.

- Status: [ ] Pending (2 days)

---

### F.14 Earnings Surprise Prediction Agent

**Goal**: In the 10-day window before a company's earnings date, aggregate news sentiment + analyst consensus trend + historical surprise patterns → LLM produces a beat/miss probability estimate as an additional signal.

**Input features per stock:**
- `avg_sentiment_5d/10d` (news tone heading into earnings)
- `analyst_buy_ratio_chg_1m` (analyst momentum)
- `days_to_earnings` (0–10 window)
- Historical `surprise_pct_last` (prior 4 quarters)

**Output**: `pre_earnings_beat_prob` (0–1) stored in `daily_symbol_features`; used as an additional factor in `score_daily_signals.py`.

**Backtest**: compare pre-earnings beat_prob vs actual surprise_pct — if IC > 0.05 across 100 symbols, add to model.

- Status: [ ] Pending (3 days)

---

### F.15 SEC EDGAR + Earnings Transcript RAG

**Goal**: Extend `quant_ai` RAG to cover SEC filings and earnings call transcripts, enabling natural language queries like "What did NVDA management say about data center margins last quarter?"

**Two sub-components:**

1. **SEC EDGAR RAG**: Use `edgartools` (already a dependency) to pull 10-K/10-Q risk factor sections → chunk → embed → store in Qdrant (separate collection from news)
2. **Earnings transcript RAG**: Pull transcripts from Seeking Alpha / Motley Fool → chunk management commentary → embed → Qdrant

**Integration with quant_ai**: Extend `/api/ask` to route queries: news questions → news collection; filing questions → edgar collection; transcript questions → transcript collection. Use query classification with a small routing prompt.

- Status: [ ] Pending (depends on F.2 Qdrant RAG; 3 days after F.2)

---

### F.16 Real-time News Monitoring Agent

**Goal**: Instead of waiting for the nightly GDELT batch, continuously monitor news feeds for currently held positions and trigger instant alerts on major negative events.

**Architecture**:
```
Every 30 min (launchd job)
    ↓
Poll NewsAPI / Finnhub news feed for held symbols
    ↓
SLM relevance filter (F.11) → discard noise
    ↓
LLM sentiment score → if negative_event_count spike detected
    ↓
Write to alerts collection → push to quant_ui (WebSocket, E.6)
```

**Trigger condition**: `avg_sentiment_3d` drops > 0.3 units from prior reading, or `negative_event_count` spike of 3+ articles in one session.

- Status: [ ] Pending (3 days)

---

### F.17 Portfolio Manager Agent (Rebalancing Recommendations)

**Goal**: After daily signals are scored, an LLM agent synthesizes current positions + new signals + regime → outputs a structured rebalancing recommendation.

**Agent output format**:
```json
{
  "add": [{"symbol": "NVDA", "reason": "score 89, regime RISK_ON, no exit signals"}],
  "reduce": [{"symbol": "LRCX", "reason": "score dropped to 41, inst_outflow trigger"}],
  "hold": ["PANW", "AMZN"],
  "regime_note": "RISK_ON — increase conviction on high-score positions"
}
```

**Revised design (2026-07-26) — review layer, not replacement**

The output format above assumed the agent decides. It should not. `track_positions.py`
already decides entries, exits, stops and holding periods deterministically, and a local
9B model would be both worse and non-reproducible at that job. Replacing tuned rules with
an LLM is a step backwards, and "why do you think the model beats your rules" is a
question with no good answer.

The agent reviews the rule engine's decisions instead, covering the two things rules
structurally cannot do:

1. **Read why a price moved.** A stop fires at −8%; the rule sees only the number. The
   agent pulls the news (I.6) and can distinguish a sector-wide selloff that has already
   reversed — a whipsaw exit — from a company-specific failure.
2. **Reason about the portfolio.** The rules are per-position. Nothing asks whether four
   of five holdings are semiconductors, or whether total exposure suits a RISK_OFF regime.

**Output**: a decision table, one row per rule action — `agree` / `flag`,
`target_weight_pct`, confidence, reasoning, and `evidence[]` where each entry is a
`(tool, field, value)` triple. Machine-consumable, so G.1 can later execute it.

**Three deterministic gates after the model replies** — none of them trust the model:
- **Schema** — valid JSON, typed fields, `action` in enum, weight in 0–100. One repair
  round-trip with the specific error, then fail loudly rather than emit garbage.
- **Grounding** — every cited `(tool, field, value)` must appear in a real observation
  from this run (float tolerance). Citations that do not are dropped with the
  recommendation. The point is not to ask the model to avoid inventing numbers; it is to
  make invented numbers non-viable.
- **Business rules** — symbol in the 100-name whitelist, ≤5% per position, exits only
  against something actually held.

**Depends on**: P.1 (a real portfolio to review), I.6 (news the agent can read).
Evaluated by F.22.

**Implementation**: `quant_ai/portfolio_agent.py` reusing `mcp_client`; no changes to
`agent.py`, `mcp_server.py`, or `mcp_client.py`. LangGraph is not needed — the existing
hand-written loop plus a validator is smaller and easier to test.

- Status: [ ] Pending (1.5–2 days; do after P.1)

---

### F.22 Agent Evaluation Harness

**Goal**: Answer "how do you know the agent is any good" with numbers instead of a demo.

**What cannot be evaluated**: whether a recommendation makes money. That needs the market
to pass. Claiming otherwise would be dishonest.

**What can be evaluated** — and these are the failure modes that actually keep agents out
of production:

| Metric | Definition |
|---|---|
| Schema validity | passed first try / passed after one repair / failed |
| **Grounding rate** | cited evidence that is real ÷ total citations |
| Tool recall | required tools that were called |
| Tool precision | called tools that were required |
| Stability | Jaccard overlap of the recommendation set across N runs of one input |
| Cost | steps, wall-clock, tokens |

The existing 7 unit tests mock the LLM, so they prove the loop is correct — not that the
decisions are. This closes that gap.

**Baseline**: the rule engine. The agent's job is not to differ from it; it is to be
justifiably different when it does. Agreement rate is itself a signal — too high and the
agent adds nothing, too low and it cannot be trusted.

**Implementation**: `quant_ai/eval/cases.yaml` (golden cases: prompt, required tools,
forbidden tools, schema, assertions) and `quant_ai/eval/run_eval.py` producing a report.

- Status: [ ] Pending (0.5–1 day; build alongside F.17)

---

### F.18 Backtest Reflection Agent

**Goal**: After each backtest run, an LLM agent automatically analyzes weak years (2022, 2024) and generates a diagnostic report with hypotheses for why the signal failed.

**Input**: year-by-year IC + Sharpe table (already produced by `factor_analysis.py`) → LLM reads the numbers and produces: "2022 failure likely driven by macro regime shift (VIX spike); macro_vix_pctile feature had negative IC that year — consider regime-conditional model."

**Output**: `backtest_reflections` MongoDB collection + downloadable PDF from UI.

- Status: [ ] Pending (2 days)

---

### F.19 LLM Factor Hypothesis Generator

**Goal**: Given the current IC table + feature correlation matrix, prompt an LLM to suggest new factor ideas not yet in the feature set.

**Prompt input**: current top/bottom IC factors, known failure modes (2022/2024), sector composition of universe.

**Expected output**: list of 5–10 testable hypotheses, e.g. "options implied volatility spread could predict 20d returns for high-beta names" or "google search trend spike 3 days before earnings beats".

**Workflow**: human reviews suggestions → select 1–2 → implement → backtest → add to model if IC > 0.05.

- Status: [ ] Pending (1 day — prompt engineering + review loop, no code pipeline needed)

---

### F.20 Dip-Buy Scanner Agent (Contrarian Entry Candidates)

**Goal**: Monitor a watchlist (held positions + custom list). When a stock is hammered by a wave of negative news or a weak earnings report, decide whether the drawdown is a *sentiment washout* (buyable dip) or *structural deterioration* (falling knife), and generate contrarian entry candidates.

**Trigger signals (all source data already collected)**:

| Signal | Source | Condition |
|---|---|---|
| Negative-news burst | `news_articles_company_matched_v2` LLM sentiment | negative article count over N days ≫ per-symbol baseline AND `avg_sentiment_5d` below threshold |
| Earnings miss | `analyst_consensus` + price data | EPS/revenue miss vs consensus, or guidance cut |
| Price washout | `stock_prices_history` | N-day drawdown > X%, sector-relative (exclude broad selloffs) |

**Agent core — dip vs falling knife triage**: an LLM reads the clustered negative articles and classifies the cause: one-off event (lawsuit, recall, single miss, sector-wide sentiment contagion) → dip candidate; structural (demand collapse, business model impairment, repeated guidance cuts) → reject. Output includes the reasoning and evidence articles.

**Output**: `dip_candidates` MongoDB collection + Slack alert (existing `send_alert` pipeline) + UI card:
```json
{
  "symbol": "PYPL",
  "drawdown_20d": -0.23,
  "neg_articles_5d": 18,
  "avg_sentiment_5d": -0.41,
  "sentiment_fading": true,
  "triage": "sentiment_washout",
  "reasoning": "Selloff driven by one-off FTC inquiry headlines; revenue guidance unchanged; negative article count decaying since day 3.",
  "watch_zone": "entry interest below 52.0 (61.8% retrace of gap)"
}
```

**Scheduling**: new DAG `quant_dip_scanner`, daily after `quant_daily_pipeline` features complete (~08:30); optional intraday re-check reusing F.16's 30-min polling.

**Phased implementation**:
1. Phase 1 — rule-based detector (no LLM): 3-signal filter → candidate list → Slack (1–2 days)
2. Phase 2 — LLM triage layer (dip vs knife) via LM Studio (2 days)
3. Phase 3 — calibrate with backtest engine: historical win rate of "20d rebound after negative-burst" → tune thresholds (2 days)
4. Phase 4 — merge into F.17 Portfolio Manager Agent as its contrarian-entry submodule

- Status: [ ] Pending (Phase 1–2 ≈ 4 days; overlaps F.14 earnings data and F.16 monitoring loop)

---

## I. MCP Integration

MCP (Model Context Protocol) standardizes how LLM clients interact with external tools and data. Adding MCP to this platform enables any MCP-compatible client (Claude Desktop, Claude Code, custom agents) to directly query signals, news, positions, and trigger backtests via natural language — with no custom API integration needed on the client side.

### I.1 quant_mcp_server — Core Platform MCP Server

**Goal**: Expose the quant platform as an MCP server so Claude or any MCP client can query live trading data through tool calls.

**MCP tools exposed:**

| Tool | Description |
|------|-------------|
| `get_signals(date?)` | Returns today's top-N signal scores, regime, signal_type |
| `get_news(symbol, days)` | Returns recent labeled articles for a symbol |
| `get_positions()` | Returns current paper positions + unrealized P&L |
| `get_factor_ic(factor?, horizon?)` | Returns IC table for a factor or all factors |
| `get_regime()` | Returns current macro regime + VIX / SPY trend |
| `run_backtest(spec_json)` | Triggers Python backtest, returns Sharpe/return/drawdown |
| `get_briefing(date?)` | Returns today's morning briefing text |

**MCP resources exposed:**
- `daily_signals` — subscribable resource; clients receive push when new signals are written

**Implementation**: Python `mcp` SDK (`pip install mcp`); standalone FastAPI server on port 18002; reads directly from MongoDB. Register in Claude Desktop `claude_desktop_config.json` for local use.

 - Status: [x] Done — six read-only tools over stdio, served through quant_api with a mongo fallback

---

### I.2 Claude Desktop Integration

**Goal**: Connect `quant_mcp_server` to Claude Desktop so daily trading analysis can happen in a normal Claude conversation — no custom UI needed.

**Usage after setup:**
> *"What's the current signal for NVDA?"* → Claude calls `get_signals()` via MCP → returns live score
> *"Show me all positions with unrealized loss"* → Claude calls `get_positions()` → filters + explains
> *"Run a backtest for a strategy that buys on avg_sentiment_5d > 0.4"* → Claude calls `run_backtest()`

**Setup**: Add `quant_mcp_server` entry to `~/Library/Application Support/Claude/claude_desktop_config.json`.

**Interview value**: "The platform is MCP-native — any Claude client can query live signals and positions without writing a single line of integration code."

 - Status: [x] Done — registered in claude_desktop_config.json, verified over the real MCP protocol

---

### I.3 Alpaca Order Execution via MCP

**Goal**: Extend `quant_mcp_server` with order execution tools so an LLM agent can read signals AND place orders through the same MCP interface — creating a true AI-driven trading loop.

**Additional MCP tools:**

| Tool | Description |
|------|-------------|
| `place_order(symbol, qty, side)` | Submit paper/live order to Alpaca; enforces pre-trade guardrails |
| `cancel_order(order_id)` | Cancel an open order |
| `get_account()` | Returns Alpaca account equity, buying power, positions |

**Safety**: All order tools enforce the same guardrails as G.1 (max 5% position, kill-switch, whitelist-only). LLM cannot bypass these — guardrails are in the MCP server, not in the prompt.

**Integration with G.1**: G.1 `live_trader.py` and this MCP tool share the same order execution logic; MCP is just an additional interface to the same engine.

- Status: [ ] Pending (2 days; requires G.1 broker integration first)

---

### I.4 External Data MCP Tools (Finnhub / EDGAR / News)

**Goal**: Wrap external data sources as MCP tools so LLM agents can autonomously decide what data to fetch during analysis — instead of hardcoding API calls.

**Tools:**

| Tool | Source | Description |
|------|--------|-------------|
| `search_news(query, days)` | NewsAPI / GDELT | Full-text news search |
| `get_earnings_calendar(symbol)` | Finnhub | Next earnings date + estimates |
| `get_analyst_ratings(symbol)` | Finnhub | Current buy/sell/hold breakdown |
| `get_sec_filing(symbol, form)` | SEC EDGAR | Pull latest 10-K or 10-Q text |
| `get_price_history(symbol, period)` | yfinance | OHLCV history |

**Value**: Agents (F.4 LangGraph, F.17 Portfolio Manager) can call these tools autonomously during reasoning, rather than having all data pre-loaded into context — reduces token usage and increases flexibility.

- Status: [ ] Pending (2 days)

---

### I.5 MCP Inter-service Communication

**Goal**: Replace the current `quant_ai → quant_api` REST calls with MCP protocol, so quant_ai becomes a proper MCP client that discovers and calls quant_api capabilities dynamically.

**Current state**: `quant_ai/main.py` hardcodes `requests.get("http://quant_api:18081/api/v1/signals/daily")` — tightly coupled.

**MCP version**: `quant_ai` connects to `quant_mcp_server` via MCP client; tool discovery is automatic; adding a new quant_api endpoint just requires registering a new MCP tool — no quant_ai code change needed.

**Interview value**: Demonstrates understanding of MCP as a service mesh protocol for AI systems, not just a chatbot feature.

 - Status: [x] Done — quant_ai's agent is an MCP client (mcp_client.py); quant_mcp was folded into quant_ai

---

### I.6 `search_news` — full-text search over labeled articles

**Goal**: Let a client read the articles, not just the average.

**Current state**: every tool on the server returns a pre-computed aggregate. A client can learn that AAPL averaged +0.31 sentiment over 90 days; it cannot read one headline behind that number, cannot ask what happened on the day of a drawdown, and has no way to check whether the aggregate is driven by ten articles or ten thousand.

**Tool**: `search_news(query, symbol=None, from_date=None, to_date=None, limit=20)` over the 845K labeled articles in `news_articles_company_matched_v2`, returning headline, date, source, `llm_sentiment_final`, and `llm_disagreement`. Needs a text index on title/body.

**Why it matters**: this is the difference between a server that reports conclusions and one that can be interrogated. It is also what lets F.17 explain a stop-loss — a mechanical rule sees −8%, only an article says whether that was a sector selloff or a company-specific failure.

- Status: [ ] Pending (0.5 day; highest-value tool remaining)

---

### I.7 `get_feature_history` — feature time series

**Goal**: Make trends visible. `get_stock_features` returns only the latest row, so "is sentiment improving or deteriorating" is unanswerable today.

**Tool**: `get_feature_history(symbol, fields, days=90)` → the selected feature columns from `daily_symbol_features` as a date-ordered series. Field whitelist, and a row cap so a client cannot pull the whole store into a context window.

- Status: [ ] Pending (0.5 day)

---

### I.8 `screen_universe` — client-driven screening

**Goal**: Let the client pose its own question instead of only consuming rankings the platform chose. "Find symbols with positive 20-day momentum but deteriorating news sentiment" is currently impossible without a new endpoint per question.

**Tool**: `screen_universe(criteria, limit=20)` — a constrained filter expression over whitelisted feature fields with comparison operators only. No free-form query strings reach the database.

- Status: [ ] Pending (1 day)

---

### I.9 `get_factor_performance` — the evidence behind a ranking

**Goal**: Expose per-factor IC by year and horizon from the existing stability analysis, so a client can explain *why* a signal ranks where it does, and can tell a factor that works from one that worked once.

- Status: [ ] Pending (0.5 day)

---

### I.10 Secondary tools

`compare_symbols(a, b)` (convenience over two calls), `get_pipeline_status()` (data freshness, last DAG run, row counts), `search_gkg(entity)` (675M-row GKG inverted index — large, but less useful for single-name work than I.6).

- Status: [ ] Pending (1 day for all three)

---

### I.11 Codex CLI as a third MCP client

**Goal**: Register the same `mcp_server.py` with Codex CLI alongside Claude Desktop and quant_ai's own agent.

**Work**: configuration only — no new code. That is the point worth making: one stdio server, three unrelated clients, and adding the third cost nothing because the tool surface is the contract.

- Status: [ ] Pending (0.5 day, mostly verification)

---

## R. AI at Scale — RAG depth and MCP depth

**Why this section exists, and why it outranks most of what is below it.**

Interview feedback, 2026-07-28 (eBay, "AI/ML Agent Engineer, backend focus"). The
recruiter's summary: positive attitude, but the interviewers "expected more knowledge of
relevant concepts and technical depth", and specifically "more experience with AI at
scale, particularly using tools like RAG and MCP". The language chosen for the technical
round was Java.

Checked against what is actually built, that feedback is precise and largely fair. It
splits into two very different problems:

**MCP has breadth without depth.** `quant_ai/mcp_server.py` is 318 lines: ten read-only
tools, three independent clients (Claude Desktop, Codex, quant_ai's own agent). The
breadth claim is real and the "one server, three clients, adding the third cost nothing"
point is a good one. What is missing is everything past the tool list:

- `stdio` is the only transport — no streamable HTTP, so no remote or multi-tenant story
- no **resources**, no **prompts**, no **sampling**, no **elicitation**, no progress
  reporting or cancellation. `@mcp.tool()` is the only part of the protocol touched
- no authentication, despite Keycloak already running in this compose stack
- every tool is read-only, so nothing exercises confirmation or idempotency
- it is entirely Python, and the role was a Java backend role

**RAG is not at scale — and the platform is exactly what makes that conspicuous.** The
whole retrieval layer is `SimpleVectorStore` in `quant_ai/main.py`: numpy cosine
similarity over the four markdown files in `quant_ai/knowledge/`, **382 lines of text
total**, re-embedded into process memory on every startup. No persistence, no chunking
strategy, no reranking, no hybrid retrieval, and no retrieval metric of any kind has ever
been computed. `retrieve_context()` falls back to keyword token overlap when the embedding
endpoint is unreachable, which in practice it often is.

Meanwhile **845K company-matched news articles sit in MongoDB with zero embeddings**, and
F.2's claim that "Qdrant already deployed" is stale — there is no `qdrant` service in
`docker-compose.yml` and never has been.

So the gap is not ignorance of RAG. It is that the single rarest asset in a RAG
interview — a large, real, domain-specific corpus with timestamps and entity labels — has
been sitting here unindexed while the demo ran on four README-sized files. "I built RAG"
survives one follow-up question and then collapses.

**One existing asset makes this cheaper than it looks.** The MongoDB text indexes with
field weights, built for I.6 `search_news`, are already a working sparse retriever. Adding
a dense leg turns them into genuine hybrid retrieval with reciprocal-rank fusion — which
is both the better architecture and the more interesting answer, since most candidates can
only describe pure vector search.

---

### R.1 Qdrant + embedding pipeline over the 845K news corpus

**Goal**: a persisted vector index over `news_articles_company_matched_v2`, replacing the
in-memory numpy store as the platform's retrieval substrate.

**Work**:
1. Add a `qdrant` service to `docker-compose.yml`, volume on the external drive alongside
   the other stateful services, **with an explicit disk cap and json-file log rotation** —
   two disk-full incidents (584G and 103G) came out of unbounded container growth, and a
   vector index is exactly the kind of thing that grows quietly.
2. Measure before committing to a full pass: embed 1,000 documents, record wall-clock
   throughput against the local LM Studio `nomic-embed-text` endpoint, then decide whether
   the full corpus is a one-night job or whether the initial index covers a date-bounded
   subset.
3. Decide chunking from measured length distribution, not by assumption.

**Measured 2026-07-30 (see "R.1 measurements" below).** Both of the assumptions this plan
originally carried were wrong, which is the argument for having measured at all:

- it guessed financial news "skews short, many rows headline-plus-lede" — **only 30.2% of
  articles fit in a single 512-token window**, median body is 2,956 characters
- it estimated 2.6 GB of vectors from one vector per article — full 512-token chunking is
  **2.96M vectors and 9.1 GB**, over the 2 GB memory cap set on the qdrant service

Two further facts neither the plan nor the README knew: **17.90% of the corpus (152,332
articles) has no body at all**, so title-only is one document in six rather than an edge
case; and **121,970 documents (14.3%) are duplicates** on `(symbol, title, date)`, which
would otherwise consume top-k slots and inflate every recall number R.4 produces.
4. Payload carries `symbol`, `date`, `event_type`, `sentiment` so retrieval can be filtered
   by entity and time window, not just similarity — a dated corpus retrieved without a
   date filter is the same look-ahead mistake as M.7, in a different costume.
5. Incremental indexing: the daily news job embeds only new documents. A pipeline that
   requires a full reindex to stay current is not a production pipeline.
6. Deduplicate on `(symbol, title, date)` at index time. 14.3% of the corpus is duplicate
   copies; a retriever that returns the same article three times has spent three of its ten
   slots saying one thing.

#### R.1 measurements (2026-07-30)

Corpus: `news_articles_company_matched_v2`, 851,071 documents.

**Length distribution** (20,000-doc sample, exact count for the no-body case):

| | value |
|---|---|
| no usable body (title only) | **152,332 = 17.90%** |
| body chars p50 | 2,956 (≈739 tokens) |
| body chars p90 / p99 | 11,492 / 60,414 |
| body chars max | 2,312,632 — whole-page scrape pollution, needs a cap |
| fits one 512-token window | **30.2%** |
| chunks/article at 512 tokens | 3.62 mean |
| duplicates on (symbol,title,date) | 40,506 groups, **121,970 extra copies = 14.3%** |

**Embedding throughput**, `text-embedding-nomic-embed-text-v1.5` (768-dim) on the local Mac
LM Studio — the Windows host in the notes was unreachable, and the model is 84 MB, so
running it locally removed a network dependency for free:

| strategy | vec/article | best rate | full corpus | wall clock | raw float32 |
|---|---|---|---|---|---|
| title + first 1000 chars | 1.00 | 74.2 vec/s | 0.85M vectors | **3.19 h** | 2.6 GB |
| 512-token chunks | 3.48 | 41.1 vec/s | 2.96M vectors | **20.00 h** | 9.1 GB |

**The finding worth keeping: throughput is character-bound, not request-bound.** Every
configuration measured 66–74 Kchar/s — batch 8 → 64 moved vector rate by 7% (69.5 → 74.2),
not 8×, and the two strategies differ 1.8× in vec/s purely because their vectors carry 1.8×
the text (946 vs 1,799 chars each). The model is saturated on tokens per second. **Batch
size is not the lever; how much text you choose to embed is.**

**Decision**: index `title + lede` first — 3.19 h is one evening against 20 h, and after
dedupe it is ~2.7 h for ~0.73M vectors. News is written inverted-pyramid, so the event
should already be in the headline and first paragraph. That is a hypothesis, not a fact,
and **R.4 is what tests it**: chunked indexing becomes a second configuration in the
ablation, and if `recall@10` justifies 9.1 GB and 20 h, the numbers will say so. Committing
20 h up front to avoid asking the question would be the more expensive mistake.

**Detail that would have silently degraded everything**: `nomic-embed-text` is asymmetric —
documents need a `search_document: ` prefix and queries a `search_query: ` one. Omit them
and vectors still come back, dimensions still match, nothing errors, and retrieval is just
quietly worse. Both benchmark strategies apply the prefix.

#### R.1 delivered (2026-07-30)

Full pass complete: **851,071 read → 729,101 indexed**, 121,970 duplicates skipped, in
**158.8 min (2.65 h) at 76.5 vec/s** — against the 2.7 h predicted from the 1K benchmark.
The duplicate count matched the independent mongo aggregate exactly (121,970), which is
the check that the pipeline's dedupe key and the measurement agreed on what a duplicate is.

`tools/index_news.py` (index), `tools/search_news.py` (query), `tools/bench_embed.py` and
`tools/measure_lengths.js` (the scripts behind every number quoted here), `tools/bench_search.py`
(latency). Committing them is the point: the numbers are reproducible rather than asserted.

**A bug caught only because retrieval was tested before the 2.65 h run, not after.** The
`date` field carries two formats, and **33.2% of the corpus is the 14-character
`YYYYMMDDHHMMSS` form**. Parsing only the 8-character case left a third of the corpus with
a null `date_int`, invisible to every date-range filter — silently, since nothing errors.
That filter is the guard against retrieving future news for a past date, so a quietly
broken one is worse than none: it looks like the guard is there. Normalised to the first 8
characters; points with a null `date_int` after the fix: **0**.

**Memory: the configuration mistake and its fix.** The service came up at **1.838 GiB of
its 2 GiB cap (92%)** — `ON_DISK_PAYLOAD` only moves the payload, and 729,101 × 768 ×
float32 = 2.24 GB of vectors was never going to fit. Setting `on_disk: true` on the vector
config (online, via `PATCH /collections`, no re-embedding) dropped it to **423 MiB (21%)**,
a 4.3× reduction with disk unchanged at 2.7 GB.

| | before | after |
|---|---|---|
| container memory | 1.838 GiB (92% of cap) | **423 MiB (21%)** |
| search p50, unfiltered | 81.90 ms | 4.44 ms |
| search p99, unfiltered | 1016.63 ms | 237.74 ms |
| search p50, date-filtered | 4.75 ms | 4.23 ms |
| embed p50 | 16.77 ms | 10.66 ms |

**The honest reading of that table**: the change is not why latency improved. Enabling
`on_disk` triggered an 80-second re-optimization, so "before" was an unoptimized index in
RAM and "after" is an optimized one on disk — two variables moved. What the numbers do
support is the useful conclusion: **memory-mapping the vectors cost no measurable latency
at this corpus size**, because 2.7 GB sits comfortably in the OS page cache. The 4.3×
memory saving is free here. It would not be at 10× the corpus, and that is the version of
this question worth being able to discuss.

- Status: [x] Done — 729,101 vectors, green, p50 15 ms end-to-end including embedding.
  Remaining for R.8: incremental daily indexing (a pipeline needing a full reindex to stay
  current is not a pipeline) and a content-hash embedding cache

---

### R.2 Hybrid retrieval — sparse + dense with RRF fusion

**Goal**: fuse the existing MongoDB weighted text index (sparse, exact-term, good on
tickers and proper nouns) with Qdrant dense retrieval (semantic, good on paraphrase), via
reciprocal-rank fusion.

**Why it matters here specifically**: `$text` search has OR semantics and scores by term
frequency, so it finds "Micron DRAM oversupply" and misses "memory glut pressures chip
makers"; dense retrieval does the reverse and is weak on exact tickers. The two failure
modes are complementary, which is the entire argument for hybrid, and this codebase can
demonstrate both halves on real queries rather than describe them.

- Status: [ ] Pending (1.5 days, after R.1)

---

### R.3 Reranking

**Goal**: retrieve top-100 by fusion, rerank to top-10 with a cross-encoder, serve the
reranked set to the LLM.

The point to be able to defend: bi-encoder similarity is a cheap approximation computed
without the query and document ever meeting; a cross-encoder scores the pair jointly and
is far better at relevance but too slow to run over 845K rows. Retrieve-then-rerank is how
that tradeoff is resolved, and the latency budget is the design constraint worth quoting.

- Status: [ ] Pending (1.5 days, after R.2)

---

### R.4 Retrieval evaluation harness — the item that actually answers the feedback

**Goal**: numbers. `recall@k`, `MRR`, `nDCG@10` on a held-out labelled query set, reported
per retrieval configuration: sparse only, dense only, hybrid, hybrid + rerank.

**Work**: build 50–100 labelled queries (question → known-relevant article ids), drawn from
real events already in the corpus — earnings reactions, export controls, the CXMT listing
from the N-series. Then an ablation table.

**Why this is ranked above R.5–R.8 in value**: "expected more technical depth" is answered
by a table showing hybrid+rerank at `recall@10 = 0.87` versus dense-only at `0.61`, and by
being able to say which queries the reranker fixed and which it broke. It is not answered
by a longer list of implemented components. F.22's evaluation harness already establishes
the pattern in this codebase — the same discipline, pointed at retrieval.

- Status: [ ] Pending (2 days, after R.3)

---

### R.5 MCP server in Java — `quant_api` as an MCP endpoint

**Goal**: a second MCP server inside `quant_api` (Spring Boot 3 / Java 21) using the MCP
Java SDK / Spring AI's MCP support, exposing the same tool surface over **streamable HTTP**
rather than stdio.

**Why this is the highest-value single item in the section for the roles being targeted**:
it is the only item that makes "Java backend engineer" and "AI at scale" the same sentence
instead of two separate claims about two separate services. The interview was a Java
interview; the MCP work was all Python. That mismatch is most of the "depth" objection.

**What it adds beyond a port**:
- **streamable HTTP transport**, so the server is reachable by remote clients — the thing
  stdio structurally cannot do, and the reason transport is a protocol concern at all
- **OAuth via the existing Keycloak realm**, so tool calls are authenticated and scoped.
  Personal holdings are already exposed over MCP with no auth whatsoever, which is fine
  for a local stdio process and indefensible over HTTP
- a defensible answer to "two servers, same tools — why?": the Python server is the local
  research surface, the Java server is the deployed authenticated one, and the tool
  contract is what makes them interchangeable to a client

- Status: [ ] Pending (1 week)

---

### R.6 MCP protocol depth — beyond tools

**Goal**: exercise the parts of MCP that `@mcp.tool()` never touches.

- **Resources**: expose the research corpus and signal history as resources with URIs and
  subscriptions, so a client reads state rather than calling a function to fetch it. The
  tool/resource distinction is a real design question, and having made the call on real
  data is worth more than knowing the definition
- **Prompts**: ship the portfolio-review and signal-explanation prompts as server-side MCP
  prompts, versioned with the server instead of pasted into each client
- **Sampling**: let the server ask the client's model to summarise retrieved news, so the
  server needs no model credentials of its own — the inversion that most people have not
  used
- **Elicitation + progress + cancellation**: required the moment a tool writes (I.3 order
  execution) or runs long (a backtest). Confirmation belongs in the protocol, not the prompt
- Structured tool output and `strict` schemas, so results are typed rather than JSON strings

- Status: [ ] Pending (3 days)

---

### R.7 RAG as a feature source, not a chat feature

**Goal**: retrieval-grounded event extraction that writes into the feature store — the
retrieval layer feeding the quant layer rather than only answering questions in a UI.

This is where the N-series propagation work and the RAG work meet: semantic retrieval over
845K articles is precisely the mechanism that finds "ChangXin Memory IPO" as relevant to
MU/WDC/STX when no article names them. Every grounded claim must carry the article ids it
came from, so a factor built this way stays auditable — and dated retrieval only, since
this is the code path where a retrieval bug becomes a look-ahead bug.

- Status: [ ] Pending (3 days, after R.2 and N.1)

---

### R.8 Production concerns at scale

The questions that separate "I built a RAG demo" from "I ran RAG in production", each
answerable with a measured number from this platform rather than a general principle:

- **Embedding cache and idempotency** — re-embedding an unchanged article is pure cost;
  content-hash keying makes the pipeline safely re-runnable
- **Index versioning and reindex strategy** — changing the embedding model invalidates
  every vector; how is that rolled out without downtime
- **Latency budget** — measured p50/p99 broken down across embed / retrieve / rerank /
  generate, so the answer to "where does the time go" is a breakdown, not a guess
- **Cost per query** at local-model throughput versus a hosted embedding API
- **Failure modes** — what is served when Qdrant is unreachable. The current fallback is
  keyword token overlap, which is honest but should be labelled to the caller, the same
  way `QuoteService` labels a daily close it is serving in place of a live quote

- Status: [ ] Pending (2 days)

---

### R.9 What to be able to answer

Not a build item — the checklist R.1–R.8 exists to make answerable. If any line here still
needs hedging after the work is done, the work is not done.

**RAG**: chunking strategy and why for this corpus · bi-encoder versus cross-encoder and
where each sits · why hybrid beats either leg alone, with the queries that prove it ·
`recall@k` / `MRR` / `nDCG` for every configuration tried · HNSW parameters and the
recall/latency curve · how the index stays current · what look-ahead means in retrieval
over a dated corpus.

**MCP**: every transport and when each applies · tools versus resources versus prompts as
a design decision · what sampling inverts and why that matters · how a write tool gets
confirmed · authorization on a remote server · why one tool contract served three clients
with no client code.

**At scale**: 845K documents, measured throughput, measured latency, measured cost — the
word "scale" carries nothing without those four numbers attached.

---

## P. Portfolio Holdings

### P.1 Manual holdings tracker

**Goal**: Record what is actually held. Everything the platform currently calls a "position" is synthetic — `track_positions.py` mechanically opens the day's top-5 signals and closes on rule triggers. That is a strategy simulation, not a portfolio, and there is nowhere to say "I own 10 NVDA from 2026-05-12".

**Data**: a `portfolio_holdings` collection — symbol, quantity, entry price, entry date, note, open/closed — plus an optional cash balance, so a weight is a share of total capital rather than a share of whatever happens to be invested.

**Surface**:
- `quant_api` — CRUD endpoints under `/api/portfolio/holdings`
- `quant_ui` — a holdings page with a table and free-form add / edit / close
- `mcp_server.py` — a read-only `get_my_holdings` tool, which makes the portfolio visible to Claude Desktop, Codex, and quant_ai's agent at once

**Why first**: both F.17 and G.1 depend on it. Neither position sizing nor a "≤5% per position" guardrail means anything measured against a portfolio nobody owns.

**Handling**: holdings are personal financial data. They stay in the local database and must never reach a seed file, a test fixture, or a commit.

**Delivered (2026-07-26)**

- `HoldingService.replay()` is a pure fold over the trade log, extracted specifically so
  the money maths is testable without a database or a quote provider. 10 unit tests:
  weighted average across mixed buys, realised P&L priced against the average *at the
  time of the sale* (folding from the end state gets this wrong), sell leaving the average
  untouched, full exit then re-entry starting fresh, overselling capped and flagged rather
  than producing a negative position.
- `QuoteService` caches Finnhub quotes for 20s. The free tier is 60 requests/minute and
  serves one symbol per call, so a page polling 20 symbols every 5s would be rate-limited
  immediately; the UI polls the cache instead and only a miss reaches Finnhub. Off-hours
  the TTL stretches to 15 minutes since prices are not moving. On failure or a missing
  token it serves the last `stock_prices_history` close tagged `source: daily-close`, and
  the UI labels it — a stale number presented as live is worse than an honest close.
- `IllegalArgumentException` now maps to 400/404 in `ApiExceptionHandler`; without it the
  hand-rolled input checks surfaced as 500s with no actionable message.
- MCP gained `get_my_holdings` and `get_my_transactions` (8 tools total). Because the
  server is the tool contract, Claude Desktop, Codex and quant_ai's agent all gained the
  portfolio at once with no client changes.

- Status: [x] Done — API + UI + MCP; F.17 is unblocked

---

## N. News Propagation — events outside the universe

**The problem.** ChangXin Memory listed and rose 471%; US memory names fell the same day.
The platform saw nothing, because it matches articles to companies by name and no article
about ChangXin mentions Micron. Generalised: any event whose *source* sits outside the
100-symbol universe — a foreign competitor, an export-control ruling, a war, an OPEC
decision — is invisible, however much it moves the portfolio.

**What is not the problem.** The corpus already covers these entities: ChangXin appears in
173 articles, 53 of them in 2026. The N.0 repair also revealed 5,688 recent articles that
name no covered company at all — general and macro news, sitting unused. The raw material
is there. What is missing is a propagation mechanism and, more importantly, evidence that
propagation predicts anything.

**The trap this series is designed around.** The motivating observation — "memory fell
today, ChangXin listed today, therefore ChangXin caused it" — is a post-hoc narrative.
Financial media supplies three plausible causes for every move. Building the capture
without the validation produces a machine that always has an explanation and never has an
edge. N.4 is therefore not a checkpoint at the end; it is the deliverable, and N.1–N.3
exist to feed it.

**How the industry does this**, for calibration:

| Approach | Who | Mechanism |
|---|---|---|
| Entity relationship graphs | Bloomberg SPLC, FactSet Revere, LSEG | curated competitor / supplier / customer edges; news propagates N hops |
| Thematic tagging | RavenPack, Accern | articles tagged by theme; themes mapped to exposure |
| Statistical co-movement | Barra, PCA factor models | peer groups learned from returns rather than curated |
| Event studies | standard academic method | distribution of abnormal returns after an event |

That Bloomberg and RavenPack charge heavily for exactly this says both that it is valuable
and that it is hard.

---

### N.0 Intraday collector schema repair — **done**

The finnhub / newsapi / yahoo collectors wrote `{source, title, description, content, url,
impact, publishedAt, collectedAt, language, meta}` — no `date`, no `symbol`. GDELT queries
per company and therefore writes both. Since `slm_company_match_v2.build_query()` requires
`{"symbol": {"$exists": True, "$ne": None}}`, everything the intraday collectors wrote from
2026-04-13 onward was invisible to the matcher: 9,636 articles, never labeled, never
featurised, never in a signal.

The consequence is exactly the capability being asked for here — same-day alerting was
impossible because same-day news never left the raw collection.

`collectors/news/_canonical.py` derives `date` from `publishedAt` in GDELT's
`YYYYMMDDHHMMSS` form and assigns a candidate symbol by keyword-matching the 100 company
rule files. Design notes worth keeping:

- **Candidate, not verdict.** The SLM validator downstream is where match accuracy is
  already engineered; this layer only has to get an article *into* that queue.
- **Conservative by construction.** AAPL's primary keyword is `Apple Inc.`, not bare
  `Apple`, so "Apple to pay Italy 318 million euros" gets no symbol. That is the right
  trade: a wrong symbol pollutes a ticker's sentiment aggregate permanently, a missing one
  costs a single article, and the validator can reject a bad candidate but never sees an
  article that has none.
- **One symbol per article**, because `url` is UNIQUE on `news_articles` — the same
  one-article-one-company shape GDELT produces.
- **Unmatched articles are kept.** 5,688 of the backfilled set name no covered company;
  they are macro and general-market news, which is the input N.1–N.3 need.

- Status: [x] Done — collectors patched, `tools/backfill_intraday_canonical.py` written and
  dry-run verified (41% match rate)

---

### N.1 Influencer entity registry

**Goal**: name the entities that move the portfolio without being in it.

A dictionary parallel to `company_rules`: foundries and memory makers (ChangXin, TSMC,
Samsung, SK Hynix, ASML), macro actors (OPEC, the Fed, export-control bodies), named
conflicts and their commodity exposure.

Each entry maps to affected symbols **with a direction**, because direction is not
derivable from the entity. A competitor's successful IPO is bearish for incumbents; rising
DRAM prices are bullish for the same names; the entity is identical in both.

- Status: [ ] Pending (1 day)

---

### N.2 Theme labels in the labeling pipeline

**Goal**: cover what an entity list cannot enumerate in advance.

The dual-LLM pass already reads every article, so a theme tag costs almost nothing at the
margin. Themes: memory cycle, AI capex, export controls, energy, conflict, rates, supply
chain.

Entity registry and themes are complementary — the registry is precise about known actors,
themes catch the ones nobody listed.

- Status: [ ] Pending (1 day)

---

### N.3 Theme → symbol exposure matrix

**Goal**: which of the 100 are exposed to "DRAM oversupply", and how much.

Seeded from the `sector` field already in `daily_symbol_features`, extended by LLM proposal
under human review. Expressed as an exposure weight rather than a boolean: MU is not
exposed to the memory cycle in the same degree as AAPL is.

- Status: [ ] Pending (1.5 days)

---

### N.4 Event-study validation — **the deliverable**

**Goal**: decide whether any of this predicts, or merely explains.

For each theme and influencer event: the distribution of **excess** returns for exposed
symbols over 1 / 5 / 20 days. Excess, not absolute — `excess_ret_*` already exists in the
feature store, and reporting absolute returns would let "memory fell on a day the whole
market fell" masquerade as a finding.

Two failure modes get measured rather than assumed away:

- **Hindsight bias** — the event list is fixed before returns are examined. Starting from a
  move and hunting for its cause reliably finds one.
- **Statistical power** — report the count of *independent* events per theme. A theme
  firing five times a year cannot support a factor whatever its point estimate; that is a
  result to publish in the report, not a reason to suppress the theme.

A negative result here is a successful outcome for this stage. It redirects N.5 rather than
blocking it.

- Status: [ ] Pending (2 days)

---

### N.5 Holdings alerting on validated themes

Extends F.16 from symbol-scoped to theme-scoped, gated on N.4: only themes shown to predict
generate an alert.

Themes that explain without predicting stay available as a research tool through the MCP
surface. Telling the user *why* a position moved today is genuinely useful and is a
different claim from telling them what to buy tomorrow. Keeping the two apart is the
discipline the series is built around, and conflating them is how a news feature becomes a
losing strategy.

- Status: [ ] Pending (1 day)

---

## J. Pipeline Workflow Orchestration & Daily Enrichment

### J.0 Current Pipeline Overview

The daily pipeline is driven by `launchd → scheduler/task.py` using the Python `schedule` library with fixed clock times. All 14 daily tasks and their implicit dependencies:

```
05:15  gdelt_backfill ──────────────────────────────────────────────────────┐
06:00  inst_13f (Sunday only) ──────────────────────────────────────────────┤
*/30m  finnhub_news / newsapi_news / yahoo_news (continuous, all day) ──────┤
                                                                             │
07:30  daily_price_quotes ──────────────────────────────────────────────────┤
07:45  premarket_signals ───────────────────────────────────────────────────┤
07:48  analyst_consensus ───────────────────────────────────────────────────┤
07:50  macro_indicators ────────────────────────────────────────────────────┤
                                                                             │ all above
                                                                             ▼
08:00  daily_symbol_features ──────── (depends on all data collectors above)
                                                                             │
                                                                             ▼
08:30  score_daily_signals ──────────────────── (depends on features)
                                │
              ┌─────────────────┴──────────────────┐
              ▼                                     ▼
08:40  track_positions                  08:45  backtest_portfolio
              │
              ▼
09:00  data_quality_check
20:30  retail_sentiment  (standalone, next-day feature input)
```

**Problem with pure time-based scheduling:**

| Risk | Current behavior | Desired behavior |
|------|-----------------|-----------------|
| Price collector fails at 07:30 | Features still run at 08:00 with stale prices | Wait for price success; skip or alert if failed |
| GDELT backfill runs >2.5 hours | Features use yesterday's GDELT news | Wait for backfill; or soft-dependency with timeout |
| Any task fails | No notification; next task starts anyway | Alert + optionally skip downstream tasks |
| Tasks have hard-coded time gaps | 30-min buffer between price (07:30) and features (08:00); fragile | Dependency → task B starts immediately when A succeeds |

---

### J.1 Airflow DAG Migration (Dependency-Based Pipeline Orchestration)

**Goal**: Replace the fixed-clock `schedule` library in `task.py` with proper Airflow DAGs that enforce task dependencies. Airflow is already deployed in Docker (`airflow-webserver:15060`); DAGs exist but haven't been validated end-to-end on the new machine.

**Target DAG: `daily_pipeline_dag`**

```
gdelt_backfill (05:15 start)
       │
       │  [timeout 4h, soft dependency]
       │
daily_price_quotes ──► premarket_signals ──┐
                         analyst_consensus ──┤
                         macro_indicators  ──┤
                                             │ all done
                                             ▼
                              daily_symbol_features
                                             │
                                             ▼
                              score_daily_signals
                                    │           │
                                    ▼           ▼
                              track_positions  backtest_portfolio
                                    │
                                    ▼
                              data_quality_check
```

**Secondary DAGs (keep separate):**
- `news_collection_dag`: finnhub/newsapi/yahoo every 30 min (TriggerRule.ALL_DONE, no upstream dep)
- `weekly_dag`: inst_13f on Sunday 06:00
- `evening_dag`: retail_sentiment at 20:30

**Key Airflow advantages over current task.py:**
1. Task failure stops downstream tasks automatically (no wasted compute on stale data)
2. Visual DAG view in Airflow UI — see which step failed without log-diving
3. Retry with backoff: `retries=2, retry_delay=timedelta(minutes=5)`
4. Cross-task XComs: backfill task can pass "rows written" count to features task
5. Backfill single DAG runs for missed dates without re-running everything

**What needs to be built:**
1. `airflow/dags/daily_pipeline_dag.py` — wire existing Python scripts as BashOperator tasks with dependencies (1 day)
2. `airflow/dags/news_collection_dag.py` — 30-min news collectors with overlap detection (1 day)
3. `airflow/dags/weekly_dag.py` — Sunday inst_13f + weekly performance summary (0.5 days)
4. Alert hook: `on_failure_callback` → writes to MongoDB `pipeline_alerts` collection; quant_api polls and sends push notification (1 day)
5. Disable corresponding jobs in `task.py` / launchd after each DAG is verified (migration, not big-bang switch)

- Status: [ ] Pending (3.5 days; Stage 7.2.2 prerequisite)

---

### J.2 Daily SLM Company Match for Realtime News (Critical Pipeline Gap)

**Goal**: Run SLM company matching on new Finnhub/NewsAPI/Yahoo articles every morning so they contribute to daily sentiment features.

**Current gap (critical):**

```
Finnhub/NewsAPI/Yahoo collectors write to news_articles
   → articles have NO "symbol" field
   → daily_symbol_features.py filters {"symbol": {"$exists": true}}
   → realtime news is COMPLETELY excluded from sentiment features
   → sentiment features only use GDELT-matched articles
```

This means `avg_sentiment_3d`, `news_burst_20d`, `high_signal_count`, and other news-based features ignore ~30–50% of available news coverage for most stocks.

**Fix**: Add a daily `slm_company_match_daily` job at ~07:55, just before `daily_symbol_features`:

```python
# Pseudocode for slm_company_match_daily.py
articles = db.news_articles.find({
    "symbol": {"$exists": False},   # unmatched realtime articles
    "publishedAt": {"$gte": three_days_ago}   # only recent articles
})
for article in articles:
    matched_symbol = run_slm_match(article["title"] + " " + article.get("content", ""))
    if matched_symbol:
        db.news_articles.update_one(
            {"_id": article["_id"]},
            {"$set": {"symbol": matched_symbol, "match_source": "slm_daily"}}
        )
```

**Implementation:**
1. Write `research/slm_company_match_daily.py` that calls `slm_company_match_v2.py` matching logic on articles with `publishedAt >= 3 days ago AND symbol not exists` (1 day)
2. Add `ENABLE_SLM_MATCH_JOB` in `task.py` scheduled at `07:55` (before `08:00` features) (0.5 days)
3. In Airflow: add as a node between news collectors and `daily_symbol_features`

**Expected impact:**
- Finnhub articles (very company-specific) → high match precision; adds targeted earnings/analyst news to sentiment
- NewsAPI/Yahoo → moderate precision; adds broad market context
- `avg_sentiment_3d` and `high_signal_count` features become richer without any feature engineering changes

**Prerequisite:** Requires LM Studio `qwen3.5-4b` loaded (same as GDELT SLM filter; no new model needed)

- Status: [ ] Pending (1.5 days)

---

### J.3 Daily LLM Sentiment Enrichment for New Articles

**Goal**: Run Gemma 3B + Qwen 4B dual-pass labeling on new articles each morning so `llm_sentiment_final` stays current (currently only historical 845K articles have labels; new daily articles don't get scored).

**Current gap**: Articles arriving via Finnhub/NewsAPI/Yahoo daily do not have `llm_sentiment_final` or `event_type` fields. The LLM labeling was a one-time batch job on historical data.

**Daily enrichment job** (`research/llm_enrich_daily.py`):

```
07:56 (after J.2 company match, before 08:00 features)
  1. Find articles: {symbol: {$exists: true}, llm_sentiment_final: {$exists: false}, publishedAt >= 3d}
  2. Pass A: Gemma 3B → raw_sentiment, event_type
  3. Pass B: Qwen 4B → cross-check; if agree → final label; if disagree → flag
  4. Write llm_sentiment_final, event_type, llm_confidence to news_articles
```

**Volume estimate**: ~500–2,000 new company-matched articles per day (Finnhub + NewsAPI + Yahoo + new GDELT);
at ~5 articles/sec (Gemma 3B), two-pass takes ~3–6 minutes → fits in the 07:56–08:00 window.

**Implementation:**
1. Write `research/llm_enrich_daily.py` using the same dual-pass logic as `llm_enrich_articles.py` but filtered to last-3d unscored articles (1 day)
2. Add `ENABLE_LLM_ENRICH_JOB` in `task.py` at `07:56` (0.5 days)
3. In Airflow DAG: `slm_company_match_daily` → `llm_enrich_daily` → `daily_symbol_features`

**Prerequisite:** Requires LM Studio `gemma3:4b` + `qwen3:4b` loaded (or a single Qwen3.5-4b if using single-pass for speed)

- Status: [ ] Pending (1.5 days; do after J.2)

---

### J.4 Pipeline Failure Alert System

**Goal**: When any daily pipeline task fails, send an immediate push notification so failures are caught before the trading day starts, not discovered hours later by checking logs.

**Current state**: Failures are logged to `pipeline_scheduler.log` only. No proactive notification.

**Implementation options (pick one):**

| Option | Description | Effort |
|--------|-------------|--------|
| Email alert | `smtplib` sends email on task failure | 0.5 days |
| Slack webhook | `POST` to Slack incoming webhook URL | 0.5 days |
| MongoDB + UI poll | Task writes `{status: "failed"}` to `pipeline_alerts`; quant_ui polls | 1 day |
| macOS notification | `osascript -e 'display notification...'` | 0.5 days |

**Recommended**: Slack webhook (works remotely; zero setup on client side; free).

**What to alert on:**
- Any `run_script_once` returns non-zero exit code
- `data_quality_check` overall status is "warn" or "fail"
- `track_positions` triggers a stop-loss exit
- `gdelt_backfill` exits with `/Volumes/Data4T` mount error (the known failure mode)
- `score_daily_signals` produces 0 LONG signals

**In Airflow**: `on_failure_callback` + `on_success_callback` for key tasks (no code change to pipeline scripts).

**In task.py (before Airflow migration)**: Wrap `run_script_once` to check `result.returncode` and call `send_alert(job_name, stderr)` on failure.

- Status: [ ] Pending (0.5 days; high impact, low effort)

---

### J.5 Intraday Position Stop-Loss Monitor

**Goal**: Check live prices during market hours (09:30–16:00 ET) every 5 minutes for held positions, and trigger a stop-loss alert instantly when price falls through the stop level — instead of waiting for the 08:40 `track_positions` next morning.

**Current behavior**: `track_positions.py` runs once at 08:40 and looks at yesterday's closing price. If a position drops 8% intraday, the stop-loss is not detected until next morning's close.

**Target**: Real-time intraday monitoring using Alpaca WebSocket streaming (the same WebSocket planned for live trading).

```
scheduler/intraday_monitor.py   (long-running process during market hours)
  │
  ├─ On startup: load current positions from MongoDB (track_positions.py output)
  │              load stop-loss levels (entry_price × (1 - stop_pct))
  │
  ├─ Connect to Alpaca WebSocket: subscribe to live quotes for held symbols
  │
  ├─ On each price tick:
  │    if current_price < stop_loss_level:
  │        → send Slack/email alert: "STOP-LOSS TRIGGERED: {symbol} @ {price}"
  │        → write to MongoDB: {event: "stop_loss_breach", symbol, price, timestamp}
  │        → if live trading enabled: submit sell order via Alpaca REST API
  │
  └─ 16:00 ET: close WebSocket, write daily EOD position summary
```

**Scheduler integration:**
- Add `ENABLE_INTRADAY_MONITOR_JOB = true` in `.env`
- `ensure_long_running("intraday_monitor", ...)` at 09:28 ET daily
- Kill/restart handled by process poll loop (already in `task.py`)

**Prerequisites:** Alpaca API key (needed for G.1 live trading anyway); no new models needed.

- Status: [ ] Pending (2 days; do after G.1 Alpaca integration)

---

### J.6 Weekly Performance Summary Report

**Goal**: Every Sunday after `inst_13f` completes, auto-generate a weekly summary: signal IC for the past week, positions opened/closed, P&L vs SPY, top/worst performers, factor attribution.

**Implementation:**
1. Write `research/weekly_summary.py` that reads last-7d `daily_signals` + `portfolio_positions` + `portfolio_performance` (1 day)
2. Format as JSON → quant_api `GET /api/weekly-report` → quant_ui weekly report tab (0.5 days)
3. Optional: send as Slack message or email attachment

- Status: [ ] Pending (1.5 days; do after J.4 alert system)

---

### J. Priority Summary

| Priority | Item | Effort | Depends on |
|----------|------|--------|-----------|
| ⭐⭐⭐ | **J.2 Daily SLM company match** (fills critical pipeline gap; realtime news → features) | 1.5 days | LM Studio qwen3.5-4b |
| ⭐⭐⭐ | **J.4 Pipeline failure alerts** (Slack webhook on task failure) | 0.5 days | None |
| ⭐⭐ | **J.3 Daily LLM sentiment enrichment** (daily Gemma+Qwen on new articles) | 1.5 days | J.2, LM Studio gemma3+qwen |
| ⭐⭐ | **J.1 Airflow DAG migration** (dependency-based DAG; replaces time-gap scheduling) | 3.5 days | Stage 7.2.2 |
| ⭐⭐ | **J.5 Intraday stop-loss monitor** (Alpaca WebSocket real-time) | 2 days | G.1 Alpaca |
| ⭐ | **J.6 Weekly performance summary** | 1.5 days | J.4 |

---

### G.1 Live Trading Execution (Automated Trading)

**Goal**: Connect the existing signal pipeline to a real broker API so that daily signals automatically place live orders, with position reconciliation and risk guardrails. This is the final step that turns the platform from a research/paper-trading system into a real execution system.

**Three-stage progression:**

```
Stage 1 (paper → broker paper account)   ← safest starting point
  track_positions.py signals
      ↓
  Alpaca Paper Trading API (free, no real money)
      ↓
  Real order book simulation with live market prices

Stage 2 (live trading, small size)
  Same signal pipeline
      ↓
  Alpaca Live API / Interactive Brokers TWS API
      ↓
  Real orders, real fills, real P&L

Stage 3 (full automation)
  launchd triggers score_daily_signals at 08:30
      ↓
  live_trader.py reads top-N signals → places market orders at open
      ↓
  Position monitor runs intraday → fires stop-loss orders if triggered
      ↓
  EOD reconciliation: compare expected vs actual fills
```

**What needs to be built:**

| Component | Description | Effort |
|-----------|-------------|--------|
| `research/live_trader.py` | Read top-N LONG signals from MongoDB → submit buy orders via broker API | 2 days |
| `research/order_manager.py` | Track open orders, handle partial fills, cancel stale orders | 2 days |
| `research/position_reconciler.py` | Compare paper positions vs broker positions; alert on drift | 1 day |
| Broker API integration | Alpaca REST API (simpler) or IBKR TWS API (more powerful) | 2-3 days |
| Pre-trade risk checks | Max position size, daily loss limit, no-trade list, market hours check | 1 day |
| Alert system | Kafka → Spring Boot → push notification on fill / stop-loss / error | 1 day |

**Pre-trade risk guardrails (non-negotiable before going live):**
- Max single position: 5% of portfolio
- Max daily drawdown kill-switch: halt all trading if down >3% intraday
- No trading in first/last 15 minutes of session (wide spreads)
- Whitelist: only trade symbols already in the 100-stock universe
- Position size = `kelly_fraction × account_equity / entry_price`, capped at 100 shares for initial testing

**Broker options:**

| Broker | API | Cost | Best for |
|--------|-----|------|---------|
| Alpaca | REST + WebSocket, Python SDK | Free (commission-free US stocks) | Starting point; easiest integration |
| Interactive Brokers | TWS API (Python `ib_insync`) | Low commission | Professional; supports options/futures later |
| Webull | Unofficial API | Free | Not recommended (unofficial) |

**Recommended starting point**: Alpaca paper account → validate that orders match signal intent → switch to live with $1K–$5K test capital.

**Key difference from paper trading:**
- `track_positions.py` simulates fills at closing price → no slippage, no partial fills, no API errors
- Live trading introduces: slippage, order rejection, partial fills, API downtime, margin calls
- Need fill confirmation loop: place order → poll for fill → update position → log to MongoDB

**Interview framing:**
*"The platform currently runs paper trading — the full signal-to-position pipeline is live, with automated entry/exit and stop-loss monitoring. The next engineering step is wiring the existing signals to a broker API (Alpaca) with pre-trade risk guardrails: position sizing, daily loss limits, and a kill-switch. The architecture is already designed for this — it's an execution layer addition, not a redesign."*

- Status: [ ] Pending (2–3 weeks for Stage 1 + Stage 2)

---

### G.2 Stock Universe Expansion

**Goal**: Grow the current 103-stock universe to cover a broader range of sectors and international names.

**Current state (2026-07-15):**
- 100 original stocks (US tech, SaaS, biotech, financials, consumer, industrials)
- 3 just added (STX, WDC, HXSCL) → **103 total**
- Storage sector is now complete: MU (DRAM), HXSCL (DRAM/NAND), STX (HDD), WDC (HDD/NAND)

**Planned expansions:**

| Phase | Symbols | Notes | Effort |
|-------|---------|-------|--------|
| Phase 1 (near-term) | STX, WDC, HXSCL | ✅ Done 2026-07-15 | 0 days |
| Phase 2 (energy/materials) | XOM, CVX, NEE, LIN, APD | Complete sector diversification; no current energy/materials coverage | 2 days |
| Phase 3 (international ADRs) | BABA, JD, PDD, BIDU, SE, GRAB | US-listed ADRs for China/SE Asia tech; significant news coverage available | 2 days |
| Phase 4 (broader S&P) | SPG, PLD, AMT (REITs), BRK-B, BAC, WFC | Financials/REITs expansion; less news-driven, lower priority | 3 days |

**What adding a new symbol requires:**
1. Add to `COMPANY_UNIVERSE` in `slm_company_match_v2.py` (keywords for news matching)
2. Collect price history: `stock_prices_history` via `daily_price_collector/collector.py`
3. Collect news history: `news_articles` via GDELT backfill (already running, just needs symbol added)
4. Run `company_match_rescore` to label historical articles for the new symbol
5. Rebuild features: `daily_symbol_features.py --symbol NEW_SYMBOL` or full rebuild
6. Re-run backtests to verify IC is stable with the expanded universe

**Note on HXSCL (SK Hynix):** Listed on US OTC markets (Pink Sheet: HXSCL). yfinance can pull price data. News coverage available via GDELT (English-language coverage of Korean semiconductor industry is substantial due to global supply chain relevance).

**Note on hourly/intraday data:** Not planned. Current strategy holds 5–60 days; daily + pre-market/after-hours gaps are sufficient. Intraday bars would only help with sub-day execution timing, which is not a priority until Stage 2 live trading is proven.

- Status: Phase 1 ✅ Done; Phases 2–4 [ ] Pending (low priority, expand only after live trading is validated)

---

## L. Multi-Frequency Strategy Layer (多周期策略扩展)

### L.0 背景：新闻信号的 IC 衰减规律

新闻驱动的信号 IC 并非在所有时间周期均等，学术研究和实践均表明：

```
信号强度（IC）随持仓周期变化示意：

    IC
  0.15 │▓▓
  0.12 │▓▓▓
  0.09 │▓▓▓▓▓
  0.06 │▓▓▓▓▓▓▓▓       ← 当前系统在此区间 (5-60d, IC≈0.059)
  0.03 │▓▓▓▓▓▓▓▓▓▓▓▓
  0.00 └──────────────────────────────────
       隔夜  1d  2d  5d  10d  20d  60d
```

**核心洞察**：新闻对价格的冲击在发布后数小时到隔夜最为集中，随后被市场消化。
当前系统只捕捉了 5–60 天的"尾部效应"，最强的短期反应被丢弃了。

**两类可扩展的短周期策略：**

| 策略 | 持仓周期 | 需要新基础设施 | 难度 |
|------|---------|--------------|------|
| L.1 隔夜新闻动量 | 收盘买入 → 次日开盘卖出 | 仅需 Alpaca 下单 | 低 |
| L.2 日内快速信号 | 1–4 小时 | 小时线 + Alpaca WebSocket | 高 |

---

### L.1 隔夜新闻动量策略 (Overnight News Momentum)

**原理**：下午盘中出现的重大正面新闻，往往在当日收盘价还未完全反映，隔夜 gap 上涨是可预测的超额收益来源。

**策略逻辑：**

```
每日 15:30 ET (收盘前 30 分钟)
  │
  ├─ 扫描过去 4 小时内所有公司匹配的新闻文章
  │    条件: publishedAt >= 11:30 AND symbol IS NOT NULL
  │
  ├─ 计算"新闻冲击分"：
  │    sentiment_spike = avg_llm_sentiment (今日) - avg_llm_sentiment (过去5日均值)
  │    news_burst     = 今日文章数 / 过去20日均值
  │    overnight_score = sentiment_spike × news_burst × analyst_surprise_weight
  │
  ├─ 选取 overnight_score 排名前 3 只股票 (同时满足 score > 阈值)
  │
  └─ 执行:
       15:55 ET: 市价买入 (收盘前 5 分钟，接近收盘价)
       次日 09:35 ET: 市价卖出 (开盘后 5 分钟，锁定隔夜 gap)
```

**为什么这个策略用现有基础设施就能实现：**
- 新闻采集：Finnhub/NewsAPI/Yahoo 每 30 分钟一次，已覆盖日内新闻 ✅
- 情绪打分：完成 J.3 后，新文章有 `llm_sentiment_final` ✅
- 下单执行：G.1 Alpaca 集成后，market order 只需一行 SDK 调用 ✅
- 不需要小时线，不需要新的数据基础设施 ✅

**新增的 pipeline 任务：**

```
scheduler/task.py 中新增:
  15:30 ET  overnight_signal_scan   # 扫描当日新闻冲击
  09:35 ET  overnight_exit          # 隔夜仓位出场
```

**因子验证（先做，再上线）：**
1. 计算历史 overnight return (收盘价 → 次日开盘价) 作为新标签
2. 用现有 `llm_sentiment_final` + `news_burst` 跑单因子 IC (目标: IC > 0.08)
3. 回测：隔夜策略的 Sharpe 预期比 20d 策略更高但波动也更大
4. 容量限制：隔夜策略仓位必须小（每笔 ≤ 2% 净值），因为流动性在收盘前变差

**与当前中频策略的关系：**
- 两套策略**完全独立运行**，不共享仓位预算
- 中频策略 (5–60d)：持仓 top-5，占用 80% 资金
- 隔夜策略：持仓 top-3，占用 ≤ 10% 资金（高换手，小仓位）
- 可以在同一个 Alpaca 账户下并行运行，用 `strategy_type` 字段区分 MongoDB 持仓记录

- Status: [ ] Pending (4 days; do after G.1 Alpaca + J.3 LLM enrichment)

---

### L.2 日内快速信号 (Intraday Fast Signal)

**原理**：重大新闻发布后，价格在最初 30–120 分钟内的动量往往持续，随后均值回归。捕捉这个初始冲击窗口。

**需要的新基础设施：**
- **小时线历史数据**：Alpaca bars API (`timeframe=1Hour`)，用于计算日内 realized volatility 和动量基准
- **Alpaca WebSocket 实时行情**：J.5 盘中监控已规划，可复用
- **更快的新闻处理**：目前 30 分钟一次采集；日内策略需要缩短到 5 分钟以内（Finnhub WebSocket 实时新闻推送）

**策略逻辑（简化版）：**

```
Finnhub 实时新闻推送 (WebSocket)
  │
  ├─ 新文章到达 → 实时 SLM company match → 情绪打分
  │
  ├─ 若 sentiment_spike > 阈值 AND 当前时间在 09:45–15:00 ET 之间:
  │    → 立即查询 Alpaca 实时报价 (bid/ask spread)
  │    → 若 spread < 0.1% AND 买入信号:
  │         → 市价买入，设置 2% 止损 + 60 分钟时间止损
  │
  └─ 持仓期间: 每 5 分钟检查动量是否衰减 → 动态出场
```

**难度较高，原因：**
- 需要 Finnhub WebSocket 实时新闻（替换现有 30 分钟轮询）
- 小时线 backfill（103 只股票 × 2 年 × 6.5h）
- 日内仓位管理更复杂（需要盘中止损 + 时间止损双重逻辑）
- 滑点和手续费对日内策略影响更大（round-trip cost 对 1–4h 持仓影响 > 对 20d 持仓 10 倍）

**前置条件**：L.1 隔夜策略验证 + Alpaca live trading 稳定运行后再考虑。

- Status: [ ] Pending (2 weeks; do after L.1 is validated live)

---

### L.3 5-Minute Bar Data Infrastructure (5分钟线数据基础设施)

**Goal**: 采集并维护 103 只股票的 5 分钟 OHLCV 数据，作为 L.2 日内策略和 J.5 盘中止损监控的数据基础。

**为什么选 5 分钟而非 1 分钟：**

| 粒度 | 年数据量 (103只) | 新闻反应窗口捕捉 | 噪声 | 推荐 |
|------|----------------|----------------|------|------|
| 1分钟 | ~1,200万行 | 过细，bid-ask spread 主导 | 极高 | ❌ |
| **5分钟** | **~240万行** | **覆盖 30–90 分钟反应窗口** | **可控** | **✅** |
| 1小时 | ~20万行 | 太粗，错过入场时机 | 低 | ❌ |

**数据来源**: Alpaca Markets bars API (`/v2/stocks/{symbol}/bars?timeframe=5Min`)
- 免费 tier 提供 2 年历史 5 分钟线
- 速率限制: 200 req/min（103 只股票 backfill 约需 20 分钟）

**存储设计**:

```
MongoDB collection: stock_prices_5min
{
  "symbol":    "AAPL",
  "timestamp": ISODate("2026-07-16T14:30:00Z"),   // UTC, 5min bar open time
  "open":      220.15,
  "high":      220.48,
  "low":       220.02,
  "close":     220.35,
  "volume":    125430,
  "vwap":      220.28
}
Index: { symbol: 1, timestamp: -1 }  (unique compound)
```

预估存储：240万行/年 × 平均 100 bytes ≈ **240MB/年**，两年历史约 500MB，可接受。

**实现步骤：**

1. **Backfill 脚本** `stock_collector/price_collector/5min_history_collector.py` (1.5 days)
   - 对 103 只股票依次调用 Alpaca bars API，拉取过去 2 年 5 分钟线
   - 写入 `stock_prices_5min`，建立 `{symbol, timestamp}` 唯一索引
   - 进度断点续传：已存在的数据跳过，从最新 timestamp 续拉

2. **每日增量采集** (0.5 days)
   - 新增 `ENABLE_5MIN_PRICE_JOB=true` 在 `.env`
   - 在 `task.py` 中添加每日 `16:35 ET` 触发（收盘后 5 分钟）
   - 只拉当天 09:30–16:00 的 5 分钟线（78 根 × 103 只 = 8034 条/天）

3. **可复用的新特征** (加入 daily_symbol_features.py 或新建 intraday_features.py)

   | 特征 | 计算方式 | 用途 |
   |------|---------|------|
   | `realized_vol_1d` | 当日 78 根 5min 收益率标准差 × √78 | 更准确的日内波动率估计 |
   | `intraday_momentum_1h` | (14:30 收盘 - 13:30 收盘) / 13:30 收盘 | 尾盘动量因子 |
   | `vwap_deviation` | (收盘价 - VWAP) / VWAP | 偏离 VWAP 程度 |
   | `open_gap_fill_ratio` | 开盘 gap 在首小时内回填比例 | 趋势 vs 均值回归判断 |
   | `volume_concentration_close` | 最后 30 分钟成交量 / 全天成交量 | 机构尾盘行为 |

4. **L.2 日内策略数据支撑**：5 分钟线提供日内动量基准和 realized vol，替代 Alpaca WebSocket 实时行情在回测中的角色

**与现有 daily price 的关系**：
- `stock_prices_history`（日线）继续维护，用于中频特征和回测，不变
- `stock_prices_5min`（5分钟线）是新增补充，仅用于日内特征和 L.2 策略

- Status: [ ] Pending (2 days total: 1.5d backfill + 0.5d scheduler integration; do before L.2)

---

### L. Priority Summary

| 优先级 | 项目 | 前置条件 | 工期 |
|--------|------|---------|------|
| ⭐⭐ | **L.1 隔夜新闻动量策略** (15:30 情绪扫描→收盘买→次日开盘卖，无需5分钟线) | G.1 Alpaca + J.3 LLM enrichment | 4 days |
| ⭐⭐ | **L.3 5分钟线数据基础设施** (Alpaca API backfill + 每日增量 + 5个日内特征) | G.1 Alpaca API key | 2 days |
| ⭐ | **L.2 日内快速信号** (5分钟线 + Finnhub WebSocket实时新闻 → 日内动量) | L.1 验证通过 + L.3 数据就绪 | 2 weeks |

---

## M. Signal Research Rigor

Hardens the signal research so its claims survive a quant-researcher-style interrogation
(IC significance? out-of-sample? survivorship bias? why not overfit?).

**This section was previously marked low priority. M.7 changes that.** The rest of the
series is about strengthening claims that are broadly sound; M.7 is a confirmed defect
that makes the headline factor invalid, and M.1 is selection bias built into the universe
before any model runs. Those two are blockers — for G.1 live execution, and for quoting
any Sharpe figure without a caveat. M.2–M.6 remain optional polish aimed at QR roles.

Accepted risk, stated plainly: rigorous treatment will probably show the signal is weaker
than the current numbers. That outcome is itself a defensible research finding when written
up honestly, and it is strictly better than discovering it after committing capital.

### M.1 Point-in-Time Universe (kill survivorship & selection bias)
Replace the hand-picked 103-stock tech universe with point-in-time S&P 500 membership
including delisted names. The current universe is the single most attackable weakness:
almost any signal "works" on a winners-only mega-cap list.
- Source historical index membership (incl. delistings), rebuild features/backtests on it
- Keep the 103-stock universe as a separate "tech sleeve" study
- Effort: 1–2 weeks (data sourcing is the hard part) — Status: [ ] Pending

### M.2 Point-in-Time Data Hygiene Audit
- Purge corrupt future-dated articles (2034/2037 timestamps in `news_articles.date`)
- Full-lineage check: for every feature, verify signal-available-time vs data-creation-time
  (news collected_at vs published_at, 13F filing lag, analyst revision lag)
- Effort: 3 days — Status: [ ] Pending

### M.3 IC Statistical Significance
- Rank IC with Newey-West adjusted t-stats (overlapping horizons inflate naive t-stats)
- IC decay curve / half-life per factor; per-year and per-regime IC stability tables
- Effort: 3 days — Status: [ ] Pending

### M.4 Factor Orthogonalization (the core question)
Does news sentiment contain information not already in price? Residualize sentiment
factors against momentum / short-term reversal / size / sector, then measure residual IC.
If residual IC ≈ 0, the "news signal" is repackaged momentum — better to know.
- Effort: 1 week — Status: [ ] Pending

### M.5 Overfitting Defenses
- Reserve a never-touched final holdout window (e.g. last 6 months) for one-shot evaluation
- Experiment registry: log every parameter combination tried (honest denominator for
  deflated Sharpe); report deflated Sharpe alongside raw
- Effort: 2 days — Status: [ ] Pending

### M.6 Research Report Writeup
Paper-style writeup: hypothesis → data → methodology → results → failure cases →
limitations. An honest "post-cost alpha is marginal, but sentiment shows orthogonal
incremental IC in earnings windows" beats a flashy Sharpe 3.0 backtest in any QR interview.
- Effort: 3 days — Status: [ ] Pending

---

### M.7 13F look-ahead leak — **blocker**

**The defect.** `inst_13f_holdings` contains exactly 100 documents, one per symbol, with
fields `{_id, symbol, collectedAt, inst_holding_pct, inst_holding_pct_chg, total_shares}`
— **no date, no quarter, no filing date**. `attach_inst13f_features()` in
`research/features/daily_symbol_features.py` left-joins on symbol alone, and its own
docstring states the intent: *"These values are quarterly; broadcast to all trade_dates for
each symbol."* A feature row dated 2018-03-15 therefore carries institutional holdings
collected in 2026.

**Why it matters more than a normal PIT slip.** `inst_holding_pct_chg` was reported as the
best single factor at **IC +0.198**, the strongest number in the Key Results table. It
scores that well *because* it leaks. Institutions accumulate what has already risen, so
projecting today's holdings backwards across eight years manufactures precisely the
correlation the IC is measuring. The factor is not merely unproven — it is measuring the
future, and it carries weight in `score_daily_signals.py` (0.5–0.6 depending on regime),
so the contamination reaches the live signal, not just the backtest.

**What makes this diagnosable rather than diffuse**: every other alt-data source in the
same file handles time correctly, which is what makes 13F an oversight rather than a design
philosophy.

| Source | Join | Verdict |
|---|---|---|
| analyst | on `YYYY-MM`; docstring says *"avoids lookahead"* | correct |
| retail | symbol + date, 1,365 rows | correct |
| macro | dated, 16,369 rows | correct |
| **13F** | **symbol only, 100 rows, broadcast** | **leaking** |

**Fix.** Source historical 13F with **filing dates** — SEC EDGAR exposes them, and the
45-day statutory reporting lag is the entire point: a Q1 position becomes public in mid-May,
so it may only enter a feature row dated on or after its filing date, never its reporting
period. Join as-of filing date, forward-fill until the next filing.

**If point-in-time 13F cannot be obtained, remove the factor.** Keeping a factor known to
read the future, with a caveat in a footnote, is worse than dropping it: the number stays in
circulation and the weight stays in the scorer. Then re-run the backtest and publish
whatever Sharpe survives — the drop is the finding.

- Effort: 2 days (1 if the decision is removal) — Status: [ ] **Pending — blocks G.1**

---

### M.8 Turnover and capacity reporting

H.1 prices a round trip per position — commission 5bps plus liquidity-tiered slippage
10/30bps, charged on entry and exit, with a filter excluding symbol-dates too thin to
execute. That model is sound per trade. What is missing is **how many trades there are**.

At a 5-day horizon fed by daily signals, turnover may be high enough that a per-trade cost
model which is honest in isolation understates total drag substantially. Report:

- annualised turnover
- transaction cost as a share of gross return
- the capital level at which the liquidity filter begins to bind

The last one converts "this strategy works" into a claim with a size attached. A result
that holds at $50k and not at $5m is a different result, and the difference is the first
thing a professional will ask about.

- Effort: 1 day — Status: [ ] Pending

---

### M.9 Short-side borrow costs

The long-short Sharpe of 0.85 charges commission and slippage on both legs but nothing for
**carrying** the short: no borrow fee, no hard-to-borrow screen, no recall risk. On exactly
the names a negative news-sentiment signal would select, borrow is where it is most
expensive — the correlation between "bad news" and "expensive to short" is not incidental.

Until this is modelled the long-short figure is optimistic by an unmeasured amount, and the
**long-only results are the more defensible ones to quote**.

- Effort: 1 day (a flat borrow-rate assumption is a legitimate first pass, provided the
  assumption is stated) — Status: [ ] Pending

---

### M.12 News syndication inflates the volume features

**Found 2026-07-30, while deduplicating the corpus for R.1** — the 121,970 rows dropped at
index time turned out not to be noise.

**The mechanism.** GDELT ingests each site of a syndication network as a separate article.
One McDonald's story on 2025-11-03 appears **402 times**: byte-identical body (767 chars),
identical sentiment, 402 distinct `*.iheart.com` subdomains. That symbol-day holds **412
rows and 11 distinct titles** — the news-volume features read 412 where the real number of
stories is 11.

`unique_url_count` exists to catch exactly this and cannot: 402 subdomains are 402 distinct
URLs. `unique_source_count` cannot either — `source.name` is absent on GDELT rows so it
falls back to the platform, and its mean is 1.0139. Both dedupe guards were structurally
blind to the dominant duplication mode.

**Measured** (`research/features/measure_syndication_impact.py` — loads the real frames and
runs the production aggregators twice, once on raw input and once deduplicated on
`(symbol, date, title)`; reusing the pipeline's own functions rather than reimplementing
them is the point):

| collection | rows | unique | duplicate |
|---|---|---|---|
| `news_articles` (volume features) | 1,750,295 | 1,494,636 | **14.6%** |
| `news_articles_company_matched_v2` (sentiment) | 851,071 | 729,101 | **14.3%** |

| feature | mean raw | mean deduped | % symbol-days differing | max abs diff |
|---|---|---|---|---|
| `article_count` | 9.104 | 7.650 | 26.4% | 664 |
| `unique_url_count` | 9.104 | 7.650 | 26.4% | 664 |
| `news_count_20d` | 181.65 | 152.65 | **93.2%** | 4019 |
| `news_burst_20d` | 1.101 | 1.059 | **93.6%** | 599 |
| `sent_wavg` | 0.3221 | 0.3224 | 15.1% | 1.253 |
| `sent_std` | 0.3019 | 0.3063 | 15.0% | 1.414 |
| `negative_n` | 1.521 | 1.228 | 5.8% | 363 |

**The damage is in the volume features, not sentiment.** `sent_wavg` barely moves in
aggregate (0.3221 → 0.3224) because a syndicated copy usually carries a sentiment close to
the day's mean anyway. `news_burst_20d` differs on **93.6% of symbol-days** — it is a
rolling ratio, so one contaminated day propagates through the following twenty.

**Why it is a cross-sectional problem rather than a level shift.** Per-symbol duplicate
share runs **2.3% to 52.4%** — a 23× spread, concentrated in consumer brands that local
radio and lifestyle networks syndicate:

    MCD 52.4  SBUX 38.3  MRNA 37.3  TGT 36.6  SPOT 36.4  BA 36.1
    UNH 33.5  PFE 32.8  LLY 32.2  DIS 31.4  NFLX 29.9   (corpus 16.0)

A uniform inflation would cancel in a cross-sectional rank. This does not: it lifts some
names by half and others by nothing, and the lift correlates with sector.

**It reaches the signal.** `news_burst_20d` carries regime weights **0.9 / 0.8 / 0.5 / 0.2**
(RISK_ON / NEUTRAL / STRESSED / RISK_OFF) in `score_daily_signals.py`, and appears in
`train_baseline_models.py` alongside `article_count` and `news_burst_20d_sector_rel`. The
sector-relative variant does not neutralise this — the bias is itself sector-correlated, so
normalising against a contaminated sector mean penalises the cleanest names in a dirty
sector. **This is the M.7 shape again**: a hand-weighted factor in the regime scorer given
high weight on top of an input nobody had validated.

#### M.12 step 2 — measured impact (2026-07-30)

Two shadow feature sets built from the same code at the same moment, differing only in
`NEWS_DEDUPE_SYNDICATION`: `daily_symbol_features_m12_off` and `_m12_on`, 191,467 rows each.
The off build was verified a genuine no-op first — 4,000 sampled symbol-days across
`article_count`, `news_burst_20d`, `news_count_20d`, `sent_wavg`, `unique_url_count`
differed from production on **0 rows**. Dedupe removed 278,327 news rows (16.0%) and
133,169 sentiment rows (15.8%).

**The ML walk-forward barely notices** (rank IC, aggregate):

| target | model | IC off | IC on | delta |
|---|---|---|---|---|
| 60d | Ensemble | 0.0572 | 0.0549 | −0.0023 |
| 60d | Ridge | 0.0491 | 0.0465 | −0.0026 |
| 60d | LightGBM | 0.0413 | 0.0413 | ±0.0000 |
| 20d | Ensemble | 0.0225 | 0.0202 | −0.0023 |

Every cell moves by less than 0.005 and the signs are not consistent — the LightGBM Ranker
gains +0.0051 at 20d and loses −0.0066 at 45d. Without error bars none of this is
distinguishable from noise, and it is **not** being claimed as an effect.

**The regime scorer does notice** (`backtest_portfolio.py`, which imports `compute_score`
and `_WEIGHTS_BY_REGIME` directly — the same path the live signal takes; 132 rebalances,
20d hold, costs on):

| | off (duplicates in) | on (deduped) |
|---|---|---|
| **net Sharpe** | 0.654 | **0.580** |
| net annualised | 19.64% | 16.76% |
| total return | 5.54× | 4.07× |
| gross Sharpe | 0.794 | 0.729 |
| max drawdown | −42.08% | **−39.56%** |
| win rate | 63.64% | **65.15%** |

**This is the M.7 pattern repeating exactly.** The ML models shrug (−0.0023 IC) because a
tree or a ridge treats `news_burst_20d` as one column among a hundred and learns its actual
predictive weight from data. The hand-weighted scorer assigned it **0.9 by fiat** and lost
**0.074 Sharpe** when the input was cleaned. Twice now, the damage from a contaminated
factor has landed almost entirely on the hand-calibrated weights rather than the fitted
ones — **the models at least look at the data before deciding how much to trust a column.**

Note the deduped run has a *better* drawdown (−39.56% vs −42.08%) and a *better* win rate
(65.15% vs 63.64%). It is a lower-return, lower-risk profile, not a uniformly worse one.

**The counter-argument worth stating**: a story syndicated to 402 stations genuinely does
have unusual reach, and reach may carry information. That does not rescue the current
feature — `article_count` claims to count distinct news and does not. If reach is the
signal, it belongs in a named feature that measures reach deliberately and can be tested on
its own, not smuggled in through a broken count.

**Conclusion**: the 0.074 Sharpe was being earned from an artifact of how GDELT ingests
syndication networks. Removing it is correct for the same reason M.7 was correct, and the
published number should come down again.

**Fix, once the impact is known**: deduplicate on `(symbol, date, title)` inside
`load_news_frame()` and `load_llm_sentiment_frame()` rather than at aggregation time, so
every downstream feature inherits it. The collectors should also stop ingesting syndicated
copies, but the feature layer must not depend on that being true.

- Status: 🟡 Measured and implemented behind `NEWS_DEDUPE_SYNDICATION`, **default off** —
  flipping the default is a production behaviour change that lowers the headline Sharpe
  from 0.654 to 0.580 on the shadow comparison, so it is held until that is a deliberate
  decision rather than a side effect. Remaining: flip the default, rebuild production
  features, re-publish the affected numbers in the README, and stop the collectors
  ingesting syndicated copies in the first place.

---

## K. Architecture & Language Decisions (决策记录)

记录已评估但主动排除的技术选型，避免未来重复讨论。

### K.1 不引入 Go / C / C++ (决策日期: 2026-07-16)

**结论**: 当前及可预见的未来不需要用 Go、C 或 C++ 替换任何现有服务。

**理由:**

| 潜在场景 | 实际瓶颈 | 结论 |
|---------|---------|------|
| GDELT 下载 / 新闻采集 | 网络 I/O，带宽限制 | Python 足够；换语言无收益 |
| LLM 推理 (Gemma / Qwen) | GPU/CPU 推理内核 | LM Studio 底层已是 C++；无需重写 |
| 特征工程 (pandas) | 内存操作，100 symbols × 189K rows | Python + numpy 足够；算法优化比语言切换收益高 |
| REST API (quant_api) | 内部服务，并发量低 | Java Spring Boot 完全足够 |
| 信号评分 / 回测 | 每日单次运行，秒级耗时 | 无延迟要求 |

**核心原因**: 策略持仓周期 5–60 天，信号只需每天 08:30 计算一次，延迟要求是**分钟级**，不是毫秒级。需要 C/C++ 的场景是 HFT（微秒级订单路由、tick 级订单簿），与本项目场景差三个数量级。

**唯一的例外条件**: 若未来升级为高频/盘中策略，需处理每秒千条以上 tick 数据，可考虑用 **Go** 编写 tick processor（goroutine 并发模型适合 WebSocket 流处理）。当前 J.5 盘中止损监控用 Python asyncio 足够。

**现有技术栈不替换的理由:**
- Python: data/ML pipeline 生态无可替代（pandas/LightGBM/LM Studio SDK）
- Java Spring Boot: REST API 生产级可用，团队已有代码资产
- React/TypeScript: 前端无替代方案

---

## Consolidated Priority Table (all pending items)

**Top of the queue, as of 2026-07-30.** The R-series is ranked above everything else pending
because it is the only block addressing named, sourced interview feedback (eBay, 2026-07-28:
"more experience with AI at scale, particularly RAG and MCP"), and because the corpus that
makes it credible — 845K articles — is already collected and sitting unindexed. R.4 and R.5
are the two that carry the weight: R.4 turns retrieval into numbers, R.5 puts MCP in Java.

| Priority | Item | Interview Value | Practical Value | Effort | Status |
|---|---|---|---|---|---|
| 🔥 | **R.1 Qdrant + embedding pipeline over 845K news** | 🔴 AI at scale — the corpus exists, unindexed | High | 3 days | 🟡 In progress (2026-07-30) — qdrant v1.18.3 deployed; corpus measured (30.2% fit 512 tok, 17.9% title-only, 14.3% dupes, 74.2 vec/s → 3.19h); pipeline not yet written |
| 🔥 | **R.2 Hybrid retrieval (Mongo weighted text + dense, RRF)** | 🔴 The answer most candidates cannot give | High | 1.5 days | [ ] Pending (after R.1) |
| 🔥 | **R.4 Retrieval eval harness (recall@k / MRR / nDCG ablation)** | 🔴 "Depth" means a table, not a longer component list | Medium | 2 days | [ ] Pending (after R.3) |
| 🔥 | **R.5 MCP server in Java (Spring AI, streamable HTTP, Keycloak OAuth)** | 🔴 Makes "Java backend" and "AI at scale" one sentence | Medium | 1 week | [ ] Pending |
| ⭐⭐⭐ | **R.3 Cross-encoder reranking** | AI essential | Medium | 1.5 days | [ ] Pending (after R.2) |
| ⭐⭐⭐ | **R.6 MCP protocol depth (resources / prompts / sampling / elicitation)** | 🔴 Everything past `@mcp.tool()` | Medium | 3 days | [ ] Pending |
| ⭐⭐ | **R.8 Scale concerns (embed cache, reindex, p99 latency, cost/query)** | AI production credibility | Medium | 2 days | [ ] Pending |
| ⭐⭐ | **R.7 RAG as a feature source (grounded event extraction → features)** | AI+Quant crossover | High | 3 days | [ ] Pending (after R.2, N.1) |
| ⭐⭐⭐ | **H.1 Backtest with transaction costs + liquidity filter** | Quant essential | 🔴 Real returns | 2 days | ✅ Done — COMMISSION_BPS=5, SLIPPAGE 10/30bps tiered, MIN_DOLLAR_VOL=$5M filter in backtest_portfolio.py |
| ⭐⭐⭐ | H.2 Market Regime detection (VIX filter) | Quant essential | 🔴 IC stability | 4 days | ✅ Done (2026-07-15) — 4-regime weight switching (RISK_ON/NEUTRAL/STRESSED/RISK_OFF) |
| ⭐⭐⭐ | H.3 Paper Trading engine + stop-loss | Quant essential | 🔴 OOS validation | 4 days | ✅ Done (2026-07-15) — vol-adaptive stop-loss (2×vol_20d) + OOS IC rolling monitor |
| ⭐⭐⭐ | Stage 7 Airflow + Kafka end-to-end | DE critical | High | 1 week | [ ] Pending (daily scheduling runs via launchd, not Airflow) |
| ⭐⭐⭐ | G.1 Live trading execution (Alpaca API) | Quant/Prod | 🔴 Real money | 2-3 weeks | [ ] Pending — paper trading done; need broker API + order manager + risk guardrails |
| ⭐ | G.2 Stock universe expansion (103→150+) | Quant bonus | Medium | 2-7 days | Phase 1 ✅ Done (STX/WDC/HXSCL added 2026-07-15); Phase 2 energy/materials [ ] Pending |
| ⭐⭐⭐ | C.2 Risk metrics (Sharpe / drawdown) | Quant essential | High | - | ✅ Done |
| ⭐⭐⭐ | C.9 Factor analysis report (IC/IR/SHAP) | Quant essential | Medium | - | ✅ Done |
| ⭐⭐⭐ | C.8 ETL unit tests | DE essential | Medium | 3 days | ✅ Done (2026-07-15) — 90 tests passing; scoring 60%, positions 52%, features 40% cov |
| ⭐⭐⭐ | E.7 README + architecture diagram | All interviews | Medium | 1 day | ✅ Done (2026-07-15) |
| ⭐⭐⭐ | Stage 7 MLflow actual runs | DE/MLE | Medium | 1 day | ✅ Done (2026-07-15) — 8 runs logged (Ridge/LightGBM/Ensemble × 20d+60d) |
| ⭐⭐ | H.4 Signal quality monitoring (rolling IC) | Quant strong | 🟡 Signal health | 2 days | [ ] Pending |
| ⭐⭐ | C.1 Daily signal automation | Medium | Extremely high | 3 days | ✅ Done (launchd, not Airflow) |
| ⭐⭐ | C.3 Signal UI page | Medium | Extremely high | 3 days | ✅ Done |
| ⭐⭐⭐ | **J.2 Daily SLM company match for realtime news** (Finnhub/NewsAPI/Yahoo → symbol field → 情绪特征) | DE关键 | 🔴 填补数据缺口 | 1.5 days | [ ] Pending |
| ⭐⭐⭐ | **J.4 Pipeline failure alert** (Slack webhook on任意任务失败) | DE essential | 🔴 运维必需 | 0.5 days | [ ] Pending |
| ⭐⭐⭐ | I.1 quant_mcp_server (signals/news/positions/backtest as MCP tools) | AI差异化 | 极高 | 3 days | ✅ Done — 10 read-only tools over stdio; depth gaps now tracked as R.5/R.6 |
| ⭐⭐⭐ | I.2 Claude Desktop integration (quant MCP → Claude对话查信号) | AI差异化 | 高 | 0.5 days | ✅ Done — verified over the real MCP protocol |
| ⭐⭐ | F.2 RAG news search UI (search box over the R.2 retriever) | AI essential | High | 1 day | [ ] Pending — retrieval superseded by R.1–R.3; "Qdrant already deployed" was never true |
| ⭐⭐ | F.3 SHAP interpretability | MLE strong | Medium | 1 day | ✅ Done (factor_analysis.py) |
| ⭐⭐ | **J.3 Daily LLM sentiment enrichment** (每日Gemma+Qwen对新文章打分，保持情绪特征最新) | MLE+DE | 高 | 1.5 days | [ ] Pending (after J.2) |
| ⭐⭐ | **J.1 Airflow DAG migration** (依赖链调度；任务失败自动停止下游；可视化DAG视图) | DE强 | 高 | 3.5 days | [ ] Pending (Stage 7.2.2) |
| ⭐⭐ | F.10 Strategy Studio → Backtest execution pipeline | AI+Quant full-loop | High | 3-4 days | [ ] Pending — UI exists, need backtest adapter + quant_api endpoint |
| ⭐⭐ | F.4 LangGraph multi-agent research assistant | AI Engineer must-have | High | 2 weeks | [ ] Pending |
| ⭐⭐ | F.17 Portfolio Manager Agent (signals+positions→rebalance recommendation) | AI+Quant | 高 | 3 days | ✅ Done (2026-07-27) — review layer over the rule engine; 3 validation gates; 25 unit tests |
| ⭐⭐ | F.16 Real-time news monitoring agent (30min轮询→即时告警) | 实用价值高 | 高 | 3 days | [ ] Pending |
| ⭐⭐ | F.14 Earnings surprise prediction (pre-earnings beat/miss概率因子) | Quant+AI | 高 | 3 days | [ ] Pending |
| ⭐⭐ | F.12 Signal explanation SLM (为高评分股票生成原因解释→UI展示) | AI+UX | 中 | 2 days | [ ] Pending |
| ⭐⭐ | I.3 Alpaca order via MCP (LLM自主决策下单，保留风控) | AI自动交易 | 极高 | 2 days | [ ] Pending (after G.1+I.1) |
| ⭐⭐ | I.4 External data MCP tools (Finnhub/EDGAR/yfinance as Agent工具) | AI Agent基础 | 高 | 2 days | [ ] Pending |
| ⭐⭐ | F.15 SEC EDGAR + earnings transcript RAG | AI+Research | 中 | 3 days | [ ] Pending (after F.2) |
| ⭐⭐ | F.8 Active learning Agent (disagreement samples) | MLE+AI | High | 4 days | [ ] Pending |
| ⭐⭐ | **F.9 Rule Optimization Agent (iterative eval→modify loop)** | AI Engineer strong | 🔴 Fixes FP/FN in rule layer | 5-7 days | 🟡 Developed, not tested |
| ⭐⭐ | E.2 CI/CD GitHub Actions | DE strong | Medium | 2 days | [ ] Pending |
| ⭐⭐ | C.7 Data quality checks | DE strong | High | 2 days | ✅ Done (data_quality_check.py) |
| ⭐⭐ | **L.1 隔夜新闻动量策略** (15:30 情绪扫描→收盘买→次日开盘卖，无需小时线) | Quant+AI | 高 | 4 days | [ ] Pending (after G.1+J.3) |
| ⭐⭐ | **L.3 5分钟线数据基础设施** (Alpaca API backfill + 每日16:35增量 + 日内特征) | Quant+DE | 高 | 2 days | [ ] Pending (after G.1 Alpaca key) |
| ⭐ | **L.2 日内快速信号** (5分钟线 + Finnhub WebSocket实时新闻 → 日内动量) | Quant+AI | 中 | 2 weeks | [ ] Pending (after L.1+L.3) |
| ⭐⭐ | B quant bonus: Long-short portfolio | Quant strong | Medium | 3 days | [ ] Pending |
| ⭐⭐ | B quant bonus: Beta neutralization | Quant strong | Medium | 2 days | [ ] Pending |
| ⭐⭐ | F.5 FinBERT fine-tuning | MLE strong | High | 1-2 weeks | [ ] Pending |
| ⭐ | F.6 rule_validator ReAct Agent | AI bonus | Medium | 3 days | [ ] Pending |
| ⭐ | F.7 Airflow adaptive scheduling Agent | DE+AI | Medium | 3 days | [ ] Pending |
| ⭐⭐⭐ | D.1 Macro Regime features (merged into H.2) | Quant essential | 🔴 Real utility | 4 days | ✅ Done |
| ⭐ | E.4 K8s configuration | DE bonus | Low | 3 days | [ ] Pending |
| ⭐ | E.5 Data lineage diagram | DE bonus | Low | 2 days | [ ] Pending |
| ⭐ | E.6 WebSocket real-time push | Backend bonus | High | 3 days | [ ] Pending |
| ⭐ | E.9 UI intraday price chart (TradingView + Alpaca API) | UI bonus | Medium | 3 days | [ ] Pending — no hourly DB needed; Alpaca API on-demand |
| ⭐ | D.2 Retail sentiment | Quant bonus | Medium | 3 days | ✅ Done (StockTwits, not Reddit) |
| ⭐ | F.1 Prompt evaluation framework | MLE bonus | Medium | 2 days | [ ] Pending |
| ⭐ | F.11 News pre-filter SLM (双LLM前加轻量二分类，降70%推理量) | ML效率 | 中 | 3 days | [ ] Pending |
| ⭐ | F.13 Morning briefing agent (07:00盘前持仓简报) | 实用 | 中 | 2 days | [ ] Pending |
| ⭐ | F.18 Backtest reflection agent (自动诊断弱年份+生成报告) | Research | 低 | 2 days | [ ] Pending |
| ⭐ | F.19 LLM factor hypothesis generator (LLM建议新因子) | Research | 低 | 1 day | [ ] Pending |
| ⭐ | I.5 MCP inter-service (quant_ai→quant_api改MCP协议) | 架构 | 低 | 3 days | [ ] Pending (after I.1) |
| ⭐ | M.1 Point-in-time S&P 500 universe (survivorship-free) | QR essential | 🔴 Signal validity | 1-2 weeks | [ ] Pending (only if targeting QR roles) |
| ⭐ | M.2 PIT data hygiene audit (dirty dates, lookahead lineage) | QR essential | 🔴 Signal validity | 3 days | [ ] Pending |
| ⭐ | M.3 IC significance (Newey-West t-stat, decay, regime tables) | QR essential | Medium | 3 days | [ ] Pending |
| ⭐ | M.4 Sentiment orthogonalization vs momentum/size/sector | QR essential | 🔴 Core question | 1 week | [ ] Pending |
| ⭐ | M.5 Overfitting defenses (holdout, trial registry, deflated Sharpe) | QR essential | Medium | 2 days | [ ] Pending |
| ⭐ | M.6 Research report writeup (paper-style, honest conclusions) | QR essential | Medium | 3 days | [ ] Pending |
| — | D.4 Analyst rating changes | Quant bonus | Medium | 3 days | ✅ Done |
| — | D.7 Institutional 13F holdings change | Quant bonus | High | 3 days | ⚠️ **Withdrawn (M.7)** — the "strongest single factor, 60d IC=+0.20" was look-ahead: one undated row per symbol broadcast across all trade dates. Factor removed; net Sharpe 0.78→0.69 |
| — | D.8 Pre-market / after-hours price signals | Quant bonus | High | 1 day | ✅ Done (strongest short-term factor, 5d IC=+0.23) |

---

# Stage 5. Engineering Extensions (post-research)

Goal: after the research stages above produce a validated signal on a
50+ symbol universe, harden the system into a production-quality full-stack
showcase. These items are intentionally scoped to exercise three skill
areas — **Java backend**, **data engineering**, and **AI/ML engineering** —
so the project becomes a multi-role interview artifact.

Do not start these until:
- universe is expanded to 50+ symbols
- year-stability analysis is complete
- at least one signal has persistent positive excess return

## 5.1 Java Backend Track

### 5.1.1 Event-driven signal distribution (Kafka)
- Spring Boot microservice publishes daily signals to a Kafka topic
- Subscribers: UI push, alerting, risk control, audit log
- Requirements: idempotent consumers, dead-letter queue, schema registry
- Deliverables:
  - `quant_signal_publisher` service
  - Kafka broker + schema registry in docker-compose
  - consumer reference implementations
- Resume framing:
  *"Designed event-driven signal distribution system using Kafka,
  supporting 40+ symbols with sub-second latency and idempotent consumers."*

### 5.1.2 Backtest orchestration API
- REST endpoint to submit backtest jobs → async worker → WebSocket push
  results
- Resilience4j circuit breakers, Bucket4j rate limiting, Redis result cache
- Keycloak JWT for auth, role-based access (researcher vs admin)
- Deliverables:
  - new endpoints under `quant_api`
  - async job queue (RabbitMQ, already present)
  - WebSocket progress stream
- Resume framing:
  *"Built async backtest orchestration service with circuit breakers,
  rate limiting, and real-time result streaming over WebSocket."*

### 5.1.3 Admin dashboard backend
- CRUD for: stock universe, job schedules, backtest experiments,
  model versions
- Audit log of every mutation
- Expand `quant_ui` with admin views
- Resume framing:
  *"Implemented admin control plane with auditable CRUD for universe,
  scheduling, and model version management."*

## 5.2 Data Engineering Track

### 5.2.1 Airflow orchestration (replace `scheduler/task.py`)
- Migrate the current monolithic scheduler to Airflow DAGs
- One DAG per domain: news ingest, price history, feature build,
  backtest, model refresh
- Backfill support, SLA monitoring, retry policies
- Deliverables:
  - `airflow/dags/` directory
  - docker-compose service for Airflow webserver + scheduler
- Resume framing:
  *"Migrated monolithic scheduler to Airflow DAGs orchestrating 15+
  daily ETL jobs with backfill, SLA, and retry policies."*

### 5.2.2 Streaming news pipeline (Kafka + Flink)
- Replace batch GDELT collector with streaming ingest
- Flink jobs: dedup → content extraction → SLM relevance → fan-out to
  MongoDB (raw) and Qdrant (embeddings)
- Exactly-once semantics where possible
- Deliverables:
  - Flink job modules
  - Kafka topic design doc
- Resume framing:
  *"Built streaming news ingestion pipeline with Kafka + Flink
  processing 1M+ articles with exactly-once semantics."*

### 5.2.3 MLflow experiment tracking
- Every backtest + model training run logged to MLflow
- Parameters, metrics, artifacts, model registry
- Deliverables:
  - MLflow server in docker-compose (Postgres backend)
  - wrapper in `research/` scripts to log runs
- Resume framing:
  *"Implemented experiment tracking with MLflow, managing 100+ backtest
  runs and model versions across Ridge / HistGB / ensemble baselines."*

### 5.2.4 dbt transformations
- Model the MySQL / MongoDB feature derivations as dbt models
- Lineage graphs, schema tests, documentation
- Deliverables:
  - `dbt_project/` with staging / intermediate / mart layers
- Resume framing:
  *"Introduced dbt for data transformations, providing lineage graphs,
  automated tests, and self-documenting feature logic."*

## 5.3 AI / ML Engineering Track

### 5.3.1 RAG news search system
- Qdrant already deployed for Dify — add a second collection for
  news article embeddings
- Service: `/search?q=NVIDIA earnings beat` → semantic recall + LLM summary
- Embedding model: `text-embedding-nomic-embed-text-v1.5` (already in
  LM Studio)
- Deliverables:
  - embedding batch job for news_articles_company_matched_v2
  - FastAPI / Spring search service
  - simple UI search page
- Resume framing:
  *"Built RAG system over 1M+ financial news articles using Qdrant
  and local LLM, supporting semantic search and summarization."*

### 5.3.2 Multi-agent research assistant (LangGraph)
- Expand the existing `langchain-agent` container into a multi-agent graph:
  - data agent: pulls relevant news / prices / earnings
  - analysis agent: extracts events, generates hypotheses
  - strategy agent: proposes factor / portfolio adjustments
  - risk agent: validates constraints
- Orchestrated with LangGraph (stateful, branching)
- Deliverables:
  - `quant_langchain/` extension with agent graph
  - demo UI or CLI
- Resume framing:
  *"Designed multi-agent financial research system using LangGraph with
  specialized agents for news analysis, signal generation, and risk
  assessment."*

### 5.3.3 SLM fine-tuning for company-match
- Use the v2 matched dataset as labeled training data
- Fine-tune Qwen3.5-4B on the company-relevance task (LoRA)
- Benchmark: base vs fine-tuned on held-out set
- Target: +5% accuracy or -30% latency at equal accuracy
- Deliverables:
  - `research/finetune_slm.py` training script
  - before/after benchmark report
- Resume framing:
  *"Fine-tuned Qwen3.5-4B with LoRA on 500K+ article classification
  dataset, improving accuracy from X% to Y% and reducing inference
  latency by Z%."*

### 5.3.4 LLM-based feature generation
- Use a larger LLM to generate enrichment features per article:
  - sentiment (-1..+1)
  - event type (earnings / product / M&A / regulation / macro)
  - entity list (companies / people)
- Store as additional fields in v2
- Feed into feature pipeline as new daily aggregates
- Deliverables:
  - batch enrichment job
  - 5-10 new daily features
- Resume framing:
  *"Added LLM-based feature extraction (sentiment, event type, entities)
  to enrich 1M+ articles, contributing to a +X% lift in model IC."*

## 5.4 Integration: End-to-End MLOps Showcase

Single flagship deliverable that ties the three tracks together:

```
Kafka (news) → Flink (clean + SLM) → Feature Store
  → Model Inference API (Spring Boot) → Kafka (signals)
  → UI + Alerts + Audit
  → Prometheus / Grafana / OpenTelemetry (monitoring)
```

This touches: event streaming, Java backend, ML inference, observability,
cloud-native deployment — interview-ready for backend, data engineer,
and AI / ML engineer roles simultaneously.

Deliverables:
- architecture diagram (`docs/architecture.md`)
- all pieces deployable via a single `docker-compose up`
- README walkthrough of the full signal lifecycle

## 5.5 Execution Order (Stage 5)

Recommended build order, each item ~1-2 weeks:

1. **5.3.1 RAG news search** — quickest AI win, reuses existing Qdrant
2. **5.2.1 Airflow migration** — immediate data-engineering credential
3. **5.2.3 MLflow tracking** — low effort, high resume value
4. **5.1.1 Kafka signal publisher** — core event-driven piece
5. **5.3.2 Multi-agent system** — deepest AI showcase
6. **5.2.2 Flink streaming** — headline data-engineering item
7. **5.3.3 SLM fine-tuning** — after enough v2 data accumulates
8. **5.4 End-to-end integration** — final polish

## 5.6 Resume Skill Coverage Matrix

| Skill                       | Covered by              |
|-----------------------------|-------------------------|
| Spring Boot microservices   | 5.1.1, 5.1.2, 5.1.3     |
| Kafka / event-driven        | 5.1.1, 5.2.2, 5.4       |
| Resilience patterns         | 5.1.2                   |
| WebSocket / real-time       | 5.1.2                   |
| Airflow / orchestration     | 5.2.1                   |
| Flink / stream processing   | 5.2.2                   |
| MLflow / experiment tracking| 5.2.3                   |
| dbt / data modeling         | 5.2.4                   |
| RAG / vector search         | 5.3.1                   |
| LangGraph / multi-agent     | 5.3.2                   |
| LLM fine-tuning (LoRA)      | 5.3.3                   |
| LLM inference at scale      | 5.3.4, existing pipeline|
| Observability / monitoring  | 5.4                     |
| Docker / K8s deployment     | 5.4                     |

---

## Stage 6 — GDELT GKG Full Index Import into MongoDB (Pending development)

### 6.1 Background and Goal

Matching historical GDELT data for new stocks currently requires scanning ~350,000 CSV files in batches, taking about 13 hours.
Goal: import 7 key columns from the CSVs into MongoDB and build a `$text` full-text index, reducing new-stock keyword matching from **13 hours → seconds**.

### 6.2 GDELT CSV column structure (7 columns retained)

| Col # | Field Name | MongoDB Field | Purpose |
|------|-----------|-----------------|------------------------|
| 1    | DATE      | `date`          | Publication date (YYYYMMDDHHMMSS) |
| 4    | URL       | `url`           | Article URL |
| 7    | V1Themes  | `themes`        | Theme keywords (primary matching) |
| 11   | V1Persons | `persons`       | Person names |
| 13   | V1Orgs    | `orgs`          | Organizations / company names (secondary matching) |
| 15   | V1Tone    | `tone`          | GCAM sentiment score (auxiliary feature) |
| 23   | AllNames  | `all_names`     | All entity names |

In the original 27-column CSV, column 17 (GCAM) accounts for 72% of the size; retaining 7 columns reduces data from 7TB to approximately **160 GB** (Parquet estimate), and MongoDB BSON + WiredTiger compression brings it to roughly **300–600 GB** (including `$text` index).

### 6.3 Development tasks

#### 6.3.1 Import script (`tools/gdelt_import_to_mongo.py`)

- Multi-process parallel read of `.csv` files (~350,000) from Data24T + Data6T
- Extract 7 columns per row; construct MongoDB document
- Write to collection `quant_data.gkg_index` in batches (batch_size=5000)
- Supports resume from checkpoint: imported files tracked in `gkg_import_progress` collection
- Deduplication: URL as unique key (`url` unique index)

```python
# Example document structure
{
    "date": "20200314120000",
    "url": "https://example.com/article",
    "themes": "ECON_BANKRUPTCY;ENV_SOLAR;...",
    "persons": "Tim Cook;Elon Musk;...",
    "orgs": "Apple Inc;Tesla;...",
    "tone": "2.5,-1.2,3.7,...",
    "all_names": "Apple-COMPANY;Tesla-COMPANY;..."
}
```

#### 6.3.2 Index creation

```javascript
// Compound text index (primary matching)
db.gkg_index.createIndex(
    { themes: "text", persons: "text", orgs: "text", all_names: "text" },
    { name: "gkg_text_idx", weights: { orgs: 10, themes: 5, all_names: 3, persons: 1 } }
)

// Auxiliary query indexes
db.gkg_index.createIndex({ date: 1 })
db.gkg_index.createIndex({ url: 1 }, { unique: true })
```

#### 6.3.3 New matching pipeline

Replace the current CSV batch scan in `historical_collector.py` with:

1. **Step 1**: `db.gkg_index.find({ $text: { $search: "keyword" } })` → returns candidate URL list in seconds
2. **Step 2**: Query `news_articles` collection; reuse already-fetched body text
3. **Step 3**: Fetch missing URLs (many old URLs from 2016-2020 may be dead; handle 404 gracefully)
4. **Step 4**: Write to `news_articles_company_matched_v2`

#### 6.3.4 Validation

- Pick 10 stocks from the existing 60; re-match using the new pipeline
- Compare URL hit rate against the current CSV approach to verify consistency
- Check `$text` index recall rate (any missed matches?)

### 6.4 Storage estimate

| Item | Estimated size |
|-----------------------------|------------|
| Raw CSV (7TB) → 7 columns extracted | ~160 GB |
| MongoDB BSON (uncompressed) | ~200 GB |
| After WiredTiger compression (~3.5x) | ~60 GB |
| `$text` index | ~200–400 GB |
| **Total (including index)** | **~300–600 GB** |

Once import is validated, the original CSVs can be deleted, saving **6TB+** of disk space.

### 6.5 Notes

- MongoDB server needs at least **600 GB** of free space (including temporary space for index build)
- Building the `$text` index will take **several hours** (570M records); recommended to create it all at once after import is complete
- V1Tone (`tone` field) format is comma-separated multiple scores; use the first value (overall sentiment score)
- Many old URLs (2016–2020) are likely dead; the URL fetching stage must handle 404/timeout gracefully and log the dead-link rate
- Import script must support parallel reads from multiple disks (Data24T + Data6T) to avoid single-disk I/O bottleneck

### 6.6 Prerequisites

- [ ] MongoDB server confirmed to have 600 GB+ free space
- [ ] Data24T and Data6T are mounted and readable
- [ ] After import, run regression tests on 10 sample stocks; delete original CSVs only after passing

---

# Stage 7 — New Mac Validation + Scheduled Task Verification + Execution Records (Pending development)

## 7.1 Background

A 48GB RAM Mac has been purchased and data/code migration is complete. A comprehensive validation of all services and scheduled tasks on the new machine is needed, along with adding observability for execution results.

## 7.2 Service validation

### 7.2.1 Docker service verification
- [ ] Verify all containers start correctly: mongo6 / quant_api / quant_ui / quant_data /
      airflow-webserver / airflow-scheduler / kafka / mlflow, etc.
- [ ] Check inter-service network connectivity (project-net internal communication)
- [ ] Verify external volume mounts are correct (MongoDB, MySQL, Airflow logs, etc. data intact)
- [ ] Confirm `.env` connection addresses are valid on the new machine

### 7.2.2 Airflow scheduled tasks running end-to-end (not just validation, must actually run)
- [ ] Check scheduling times and dependencies for all DAGs in `airflow/dags/`
- [ ] Manually trigger each DAG; confirm full end-to-end execution succeeds (not just "defined")
- [ ] Confirm Docker socket mount path is correct (`/var/run/docker.sock`)
- [ ] Wait for at least one automatic schedule trigger; confirm timed execution works
- [ ] Check DAG execution logs; fix any failing tasks
- [ ] Goal: news collection / feature build / model training — all three main DAGs running stably

### 7.2.3 Kafka actually running (not just deployed, must have real data flow)
- [ ] Confirm kafka container is healthy and reachable at `kafka:9092`
- [ ] Create required topics (e.g. `quant.signals`, `quant.news`)
- [ ] Implement at least one producer: push to `quant.signals` topic after daily signal generation
- [ ] Implement at least one consumer: consume signals and write to `daily_signals` collection or trigger alert
- [ ] Verify message flow through kafka-ui (port 15070)
- [ ] Goal: signal generation → Kafka → consume and write to DB — full pipeline running

### 7.2.4 MLflow actual run recording
- [ ] Confirm mlflow container is healthy (port 15050)
- [ ] Enable `--mlflow-uri` in `train_baseline_models.py`; run one training and record
- [ ] Verify parameters, metrics, and model files are visible in MLflow UI
- [ ] Goal: every model training run is recorded; IC / Top5 excess return is traceable

### 7.2.5 LLM inference validation
- [ ] Verify LM Studio / Ollama is available on the new Mac and models are loaded
- [ ] Verify `SLM_API_URL` environment variable points to the correct endpoint
- [ ] Run a small batch of `llm_enrich_articles.py` to confirm inference is working

## 7.3 Execution result recording (UI / API)

Current problem: execution results for Airflow and Python scripts (success/failure, rows processed, duration, key metrics) have no unified visibility entry point, making troubleshooting difficult.

### 7.3.1 quant_api execution log endpoint
- [ ] Add `pipeline_runs` collection (MongoDB) or table (MySQL) to record each task execution:
  ```json
  {
    "task_name": "feature_build",
    "started_at": "2026-05-22T21:00:00Z",
    "finished_at": "2026-05-22T21:03:00Z",
    "status": "success",
    "rows_processed": 134642,
    "error_message": null,
    "metadata": { "collection": "daily_symbol_features_company_matched_v2" }
  }
  ```
- [ ] quant_api provides REST endpoints: `POST /api/pipeline-runs` (write) and
      `GET /api/pipeline-runs` (query most recent N records)
- [ ] Each Python script (daily_symbol_features.py, llm_enrich_articles.py, etc.)
      calls the endpoint to report results after completion

### 7.3.2 quant_ui execution history page
- [ ] Add a "Task Execution Records" page in the UI showing:
  - Task name, status (success/failure), start/end time, rows processed
  - Execution trend chart for the last 30 days
  - Failed tasks highlighted + error message display
- [ ] Support filtering by task name and time range

### 7.3.3 Model training result persistence
- [ ] After each `train_baseline_models.py` run, write per-horizon IC / Top5 excess return
      to `model_results` collection with timestamp and feature set version tag
- [ ] quant_ui displays model historical result trends to facilitate comparison across different feature versions

## 7.4 Priority

1. Docker baseline service validation (blocks all subsequent work)
2. **Airflow DAG actually running** (not just defined; must run stably — key interview proof)
3. **Kafka producer/consumer actually running** (signal → topic → consume and write to DB full pipeline)
4. **MLflow actual run recording** (every training run is traceable)
5. quant_api execution log endpoint (pipeline_runs write to DB)
6. quant_ui execution history page
7. Model result persistence

---

## G. Reference Resources (compiled 2026-05-22)

### G.1 LLM sentiment factor / alpha mining papers

| Paper | Key points |
|------|------|
| [Event-Aware Sentiment Factors from LLM-Augmented Financial Tweets (arXiv 2508.07408)](https://arxiv.org/pdf/2508.07408) | Interpretable LLM quantitative framework, event-aware sentiment factor construction; useful to compare against this project's LLM tagging approach |
| [Interpretable ML for Macro Alpha: News Sentiment Case Study (arXiv 2505.16136)](https://arxiv.org/pdf/2505.16136) | FinBERT + GDELT → FX/treasury strategy, OOS Sharpe >4; validates the GDELT + LLM approach |
| [AlphaAgent: LLM-Driven Alpha Mining (arXiv 2502.16789)](https://arxiv.org/html/2502.16789v2) | LLM-automated alpha factor mining including anti-decay mechanism |
| [Automate Strategy Finding with LLM in Quant Investment (arXiv 2409.06289)](https://arxiv.org/html/2409.06289v1) | LLM-driven strategy discovery pipeline; useful prompt design reference |

### G.2 CBOE options data (free download)

- **PCR historical CSV** (for D.5 Put/Call Ratio factor):
  `https://cdn.cboe.com/resources/options/volume_and_call_put_ratios/indexpcarchive.csv`
- **CBOE historical data main page**:
  `https://www.cboe.com/us/options/market_statistics/historical_data/`
- Usage: load daily PCR data directly with `pd.read_csv(url)`; no registration required

### G.3 FinBERT fine-tuning resources (for F.5 / Stage 3.5.5)

| Resource | Key points |
|------|------|
| [Fine-Tuning FinBERT for Sector-Specific Financial News (MDPI Electronics 2025)](https://www.mdpi.com/2079-9292/14/23/4680) | zero-shot F1=0.555 → after fine-tuning F1=**0.707**; includes sector-specific training approach, directly applicable as training script reference |
| [ProsusAI/finbert on HuggingFace](https://huggingface.co/ProsusAI/finbert) | Official FinBERT pre-trained weights, ready to load |
| [Efficient FinBERT via Quantization (ACL FinNLP 2025)](https://aclanthology.org/2025.finnlp-2.6.pdf) | INT8/INT4 quantization compression; runnable locally on Mac M-series chips |

### G.4 SEC EDGAR 13F Python tools (for D.7)

| Library | Description |
|----|------|
| [edgartools](https://github.com/dgunning/edgartools) | **Preferred**, free and open-source; parses 13F into structured Python objects; data goes back to 2005; `pip install edgartools` |
| [sec-api-python](https://github.com/janlukasschroeder/sec-api-python) | Paid SDK with free trial quota; suitable for bulk production scraping |

---

## H. Live Trading System Roadmap (from research → truly usable)

### Background: why live trading is not yet possible

Backtest results (long-short annualized +21.7%, Sharpe 0.85) look promising, but the following issues would cause real money to lose:

| Problem | Specific manifestation | Risk level |
|------|---------|---------|
| IC year-over-year instability | IC was negative in 2022/2024/2025, signal reversed | 🔴 Fatal |
| No transaction costs | Backtest does not deduct commissions + slippage; real returns reduced by 30-40% | 🔴 Fatal |
| Signal lag | LLM processing takes several hours after news is published | 🟡 Serious |
| No position sizing | Equal-weight allocation; single-stock risk is unconstrained | 🟡 Serious |
| No out-of-sample validation | All data used for backtest; overfitting risk | 🟡 Serious |
| Only 100 stocks | Concentration too high; liquidity risk | 🟠 Moderate |

---

### H.1 Fix backtest realism (🔴 must do first)

**H.1.1 Add transaction cost model**
- One-way commission: 0.05% (standard broker level)
- Slippage model: 0.3% for small-cap, 0.1% for large-cap (tiered by market cap)
- Modify `backtest_news_factor.py` and `backtest_event_driven.py`:
  ```python
  net_return = gross_return - commission * 2 - slippage * 2
  ```
- Goal: determine how much of the long-short annualized return remains after costs
- Status: [ ] Pending development (1 day)

**H.1.2 Add liquidity filter**
- Exclude stocks with average daily volume < $5M (avoid execution failure)
- Add `avg_daily_volume` feature; filter at position selection
- Status: [ ] Pending development (0.5 days)

**H.1.3 Add position limit constraints**
- Max position per stock: 5% (avoid over-concentration)
- Max position per sector: 25%
- Modify `score_daily_signals.py` to add position constraint logic
- Status: [ ] Pending development (0.5 days)

---

### H.2 Resolve IC instability (🔴 must do first)

**H.2.1 Market Regime detection**

Year-by-year IC analysis reveals the signal is only effective in "trending markets":
```
2022 (bear market / high VIX): IC = -0.035 → disable signal
2023 (recovery / low VIX):     IC = +0.163 → enable signal  
2024 (choppy):                  IC = -0.022 → disable signal
2025 (choppy):                  IC = -0.020 → disable signal
```

Implementation:
- Data source: `yfinance` for daily VIX data
- Regime definitions:
  - **Trending market**: VIX < 20 AND SPY 20-day moving average trending up → enable LLM sentiment factor weighting
  - **Choppy / panic**: VIX > 25 → reduce position to 50%, switch to mean-reversion factors
- New field: `market_regime` (trend / volatile / crisis)
- Adjust composite_score weights by regime in `score_daily_signals.py`
- Status: [ ] Pending development (2 days)

**H.2.2 Dynamic factor weights**
- Different factor weights for different regimes:
  - Trending market: LLM sentiment weight 40%, momentum weight 30%, earnings weight 30%
  - Choppy market: LLM sentiment weight 10%, mean-reversion weight 50%, earnings weight 40%
- Add `market_regime` as a feature during model training, or train separate models per regime
- Status: [ ] Pending development (2 days)

---

### H.3 Paper Trading validation (🔴 must do, run for at least 3-6 months)

**Goal**: validate signals in a real market environment and accumulate out-of-sample data

**H.3.1 Paper Trading engine**
- Execute automatically after market close each day:
  1. Read the top 10 stocks by composite_score from that day's `daily_signals`
  2. Check regime: if VIX > 25, skip or halve the position
  3. Simulate order entry; record entry price (use next day's open price)
  4. Write to `paper_positions` collection
- Fields: `symbol`, `entry_date`, `entry_price`, `size`, `score_at_entry`, `regime_at_entry`
- Status: [ ] Pending development (2 days)

**H.3.2 Paper Trading performance tracking**
- Update unrealized P&L daily
- Compute real out-of-sample IC (each day's actual holdings: predicted vs actual performance)
- Target metrics:
  - OOS IC > 0.02 (signal is effective in real markets)
  - OOS Sharpe > 0.5 (strategy is executable)
  - 3 consecutive months of positive excess return (signal is stable)
- Status: [ ] Pending development (1 day)

**H.3.3 Stop-loss and exit logic**
- Per-stock stop-loss: auto-exit if the position drops -5% from entry
- Sentiment reversal stop-loss: if `avg_sentiment_5d` turns negative during holding, actively exit
- Time stop-loss: auto-exit if holding exceeds `max_hold_days` (default 45 days)
- Status: [ ] Pending development (1 day)

---

### H.4 Signal quality monitoring (🟡 important)

**H.4.1 Real-time IC monitoring**
- Compute rolling IC over the most recent 20 trading days every day
- If IC stays below 0 for 5 consecutive days → trigger alert, pause new position entries
- Write to `signal_quality` collection; UI displays IC trend chart
- Status: [ ] Pending development (1 day)

**H.4.2 Model drift detection**
- Weekly: compare the latest feature distribution against the training-time distribution (KL divergence)
- If distribution shift exceeds threshold → trigger retraining reminder
- Status: [ ] Pending development (1 day)

---

### H.5 Live trading readiness checklist

All of the following must be satisfied before considering real capital:

- [ ] Paper trading has run for **at least 3 months**, OOS IC > 0.02
- [ ] Backtest Sharpe **remains > 0.5** after including transaction costs
- [ ] Regime detection works correctly; automatically reduces position when VIX > 25
- [ ] Stop-loss logic tested (simulated extreme market conditions)
- [ ] Max position per stock ≤ 5%; overall leverage = 1x (no leverage)
- [ ] Broker API connected (Interactive Brokers / Alpaca)
- [ ] First live-trading capital ≤ 10% of total capital (testing phase)

---

### H. Roadmap overview

```
Now (research validation complete)
    ↓
H.1 Fix backtest realism (3 days)        ← know the real returns
H.2 Regime detection (4 days)            ← know when to use the signal
H.3 Paper Trading (1 month to get going) ← real-market validation
    ↓ continue running 3-6 months
H.4 Signal monitoring (2 days)           ← keep signal effective
    ↓ paper trading metrics pass
H.5 Live trading checklist all ✓
    ↓
Small live position (≤10% of total capital)
    ↓ 6 months of stable excess return
Truly usable quantitative trading system ✓
```

---

## G. Strategy Generation Complete Implementation Plan (quant_langchain)

> Current state: `quant_langchain/main.py` already has the endpoint framework for `/api/workflow/generate-spec` and `/api/workflow/generate-tasks`, but all three core features are stub implementations that need to be completed.

---

### G.1 RAG — Replace keyword matching with vector retrieval (3 days)

**Current problems:**
- `retrieve_context()` scores by keyword token overlap, not semantic retrieval
- The knowledge directory has only 1 file (26 lines); RAG has almost no real effect
- Low hit rate: user input "RSI mean reversion" cannot match if phrased differently

**Goal:** Replace keyword matching with Qdrant (already running in docker-compose) for true vector semantic retrieval

**Development steps:**

1. **Add knowledge base documents** (1 day)
   - `knowledge/strategies/` — strategy templates: RSI, MACD, momentum, mean-reversion examples
   - `knowledge/factors/` — factor descriptions: IC per factor, use cases, parameter ranges
   - `knowledge/risk/` — risk control rules: stop-loss, position, max drawdown defaults
   - `knowledge/modules/` — detailed parameter descriptions for each module in MODULE_CATALOG

2. **Integrate Qdrant vector retrieval** (2 days)
   - Install: `langchain-qdrant`, `sentence-transformers`
   - Embed knowledge documents with `all-MiniLM-L6-v2`; write to Qdrant
   - Replace `retrieve_context()` with `qdrant_client.search(query_vector, top_k=4)`
   - Build index asynchronously at startup; support incremental updates

**Done when:** Input "RSI buy when oversold" retrieves the RSI strategy template document

---

### G.2 MCP — Tools actually executable (4 days)

**Current problems:**
- Module paths in `MODULE_CATALOG` (e.g. `quant_langchain.features.momentum`) do not exist
- LLM only "sees" the tool list in the prompt; it cannot actually call them
- No tool call loop: module names in the LLM-generated spec are hallucinated and never executed

**Goal:** Wrap each tool in MODULE_CATALOG as a callable function; close the loop of LLM → tool call → result returned

**Development steps:**

1. **Implement tool functions** (2 days)

```python
# quant_langchain/tools/market_data.py
def fetch_market_data(symbols: list, timeframe: str, lookback_days: int) -> dict:
    """Call quant_api /api/signals to fetch historical signals and price data"""
    resp = requests.get(f"{QUANT_API}/api/signals", params={"symbols": symbols})
    return resp.json()

# quant_langchain/tools/feature_builder.py
def build_features(indicators: list, window: int) -> dict:
    """Call quant_api /api/features to get feature data"""
    ...

# quant_langchain/tools/backtest.py
def backtest_strategy(spec: dict, initial_cash: int, fee_bps: int) -> dict:
    """Generate backtest summary based on spec (calls quant_data research module)"""
    ...
```

2. **Register tools with LangChain** (1 day)
   - Register each function with the `@tool` decorator
   - Change the `generate-spec` endpoint to use `AgentExecutor` so the LLM actually calls tools
   - Collect results from each tool call and assemble into the final spec

3. **MCP protocol wrapping (optional upgrade)** (1 day)
   - Add JSON schema description for each tool
   - Output format complies with MCP tool result spec
   - Prepares for future Claude MCP integration

**Done when:** Spec generation logs show `[Tool Call] fetch_market_data(AAPL, daily, 60)` → real data returned

---

### G.3 API Key routing — proactive tiering by task complexity (1 day)

**Current problems:**
- Uses `OpenAI` (text completion); should switch to `ChatOpenAI` (chat model)
- Routing logic only falls back when Ollama is down; no proactive model selection by task type
- `LLMChain` is a deprecated API; should migrate to LCEL (LangChain Expression Language)

**Goal:** Local small model handles simple tasks; cloud large model handles complex reasoning

**Routing rules:**

| Task | Model | Reason |
|------|------|------|
| generate-spec (simple strategy) | Qwen3-8B local | MODULE_CATALOG constrains output; structure is fixed |
| generate-spec (complex multi-factor) | Claude Sonnet / GPT-4o | Factor combination reasoning; small models hallucinate |
| generate-tasks (code generation) | Claude Sonnet / GPT-4o | High code quality required |
| chat (strategy Q&A) | Qwen3-8B local | Many conversation turns; cost-sensitive |

**Development steps:**

```python
# Switch to ChatOpenAI + LCEL
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

def get_llm(task_type: str = "simple"):
    # Proactively use cloud model for complex tasks
    if task_type == "code_generation" and ANTHROPIC_API_KEY:
        return ChatAnthropic(model="claude-sonnet-4-6", api_key=ANTHROPIC_API_KEY)
    if task_type == "complex_spec" and OPENAI_API_KEY:
        return ChatOpenAI(model="gpt-4o-mini", api_key=OPENAI_API_KEY)
    # Default to local
    try:
        # health check Ollama...
        return ChatOllama(model=LOCAL_MODEL_NAME)
    except:
        return ChatOpenAI(model="gpt-4o-mini", api_key=OPENAI_API_KEY)
```

**Done when:** generate-tasks endpoint logs show `[Router] task=code_generation → claude-sonnet-4-6`

---

### G.4 Priority and time estimate

| Priority | Feature | Effort | Value |
|--------|------|--------|------|
| 🔴 Highest | G.2 MCP tools actually executable | 4 days | Strategy generation changes from "hallucinated output" to "real execution" |
| 🟠 High | G.3 API Key routing refactor | 1 day | Code quality improvement; deprecated API removed |
| 🟡 Medium | G.1 RAG vector retrieval | 3 days | Retrieval precision improved; interview demo highlight |

**Total timeline: approximately 8 days**

Recommended order: G.3 (1 day, base layer) → G.2 (4 days, tool layer) → G.1 (3 days, knowledge layer)

**Estimated time from now to "truly usable": approximately 6-9 months** (of which 3-6 months is waiting for paper trading data to accumulate)
