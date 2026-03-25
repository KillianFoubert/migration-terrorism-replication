# Global Migration and the Role of Terrorist Attacks

## Replication Code

This repository contains the Stata replication code for:

**Foubert, K. & Ruyssen, I. (2024).** Global migration and the role of terrorist attacks. *Journal of Economic Behavior and Organization*, 220, 507–530. [https://doi.org/10.1016/j.jebo.2024.02.022](https://doi.org/10.1016/j.jebo.2024.02.022)

## Abstract

This paper analyses how terrorism has shaped global bilateral migration in the past decades. Combining data on yearly bilateral migration rates with data on terrorist activity in 154 countries of origin and destination over the period 1975–2017, we find that terrorism acts both as a push factor for migration and as a repulsive factor for location choice. Migration rates respond primarily to variations in the intensity rather than the mere occurrence or frequency of attacks. Terrorism induces international emigration only at extreme levels, while modest levels of terrorism are already enough to reduce a country's attractiveness to potential migrants.

## Data Sources

The analysis combines data from the following sources. **The datasets are not included in this repository** as most require licences or registration:

| Source | Variable(s) | Access |
|--------|-------------|--------|
| Annual Bilateral Migration Database (ABMD) | Bilateral migration flows & stocks | [RIKS platform](https://riks.cris.unu.edu) |
| Global Terrorism Database (GTD) | Terrorist attacks indicators | [START, University of Maryland](https://www.start.umd.edu/gtd/) |
| Penn World Table 10.0 | GDP per capita | [PWT](https://www.rug.nl/ggdc/productivity/pwt/) |
| World Development Indicators (WDI) | Population, GNI per capita | [World Bank](https://databank.worldbank.org/) |
| Polity IV Project | Political instability | [Center for Systemic Peace](https://www.systemicpeace.org/) |
| UCDP/PRIO Armed Conflict Dataset | Conflict occurrence | [UCDP](https://ucdp.uu.se/) |
| CEPII GeoDist | Distance, contiguity, common language | [CEPII](http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele.asp) |
| Database of Political Institutions (DPI 2020) | Government fractionalization | [World Bank](https://datacatalog.worldbank.org/) |
| Ethnic & Religious Fractionalization | Fractionalization indices | Constructed from source data |
| Worldwide Governance Indicators (WGI) | Quality of institutions | [World Bank](https://info.worldbank.org/governance/wgi/) |
| UNHCR / WDI | Refugee flows | [World Bank](https://databank.worldbank.org/) |
| GADM | Country shapefiles (ISO3 codes) | [GADM](https://gadm.org/) |

## Repository Structure

```
code/
├── 01_data_cleaning/          # Data preparation (one do-file per source)
│   ├── 00_creating_iso3_codes.do          # ISO3 country codes (run first)
│   ├── 01_migration_ABMD.do               # Migration flows, stocks & network
│   ├── 02_terrorism_GTI.do                # GTI construction + spatial lag
│   ├── 03_terrorism_GTI_without_9-11.do   # GTI excluding 9/11 (robustness)
│   ├── 04_WDI_population_GNI.do           # Population, GNI, income thresholds
│   ├── 05_PWT_GDPpc.do                    # GDP per capita (Penn World Table)
│   ├── 06_polity_IV.do                    # Political instability (Polity IV)
│   ├── 07_conflicts_UCDP.do              # Armed conflicts (UCDP/PRIO)
│   ├── 08_CEPII_gravity.do               # Gravity variables (CEPII)
│   ├── 09_govt_fractionalization.do       # Government fractionalization (IV)
│   ├── 10_ethnic_religious_frac.do        # Ethnic & religious fractionalization
│   ├── 11_quality_institutions.do         # Quality of institutions (WGI)
│   └── 12_refugees_WDI.do                # Refugee flows
│
├── 02_merge/
│   └── 13_merge_final.do                  # Merges all sources into final panel
│
├── 03_estimations/
│   └── 14_estimations.do                  # All PPML & IV estimations (Tables 1–5)
│
└── 04_descriptives/
    └── 15_descriptive_statistics.do       # Summary statistics, maps, correlations
```

## Execution Order

Scripts are numbered to indicate execution order:

1. **Run `00` first** — it creates the ISO3 code files used by all subsequent scripts.
2. **Run `01` through `12`** in any order — each cleans one data source independently.
3. **Run `13`** — merges all cleaned datasets into the final bilateral panel.
4. **Run `14`** — produces all estimation results (Tables 1–5 and appendix tables).
5. **Run `15`** — generates descriptive statistics, maps, and correlation tables.

**Note:** File paths in the do-files reference the authors' local Dropbox directories. Users will need to adjust the `cd` commands at the top of each file to match their own directory structure.

## Software Requirements

- Stata 16 or later
- Required Stata packages: `ppmlhdfe`, `reghdfe`, `ivreg2`, `ranktest`, `ftools`, `estout`, `spmat`, `shp2dta`, `spmap`, `wbopendata`, `carryforward`, `sutex`

To install all packages:
```stata
ssc install ppmlhdfe
ssc install reghdfe
ssc install ivreg2
ssc install ranktest
ssc install ftools
ssc install estout
ssc install spmap
ssc install shp2dta
ssc install wbopendata
ssc install carryforward
ssc install sutex
```

## Methods

- Pseudo-Poisson Maximum Likelihood (PPML) with high-dimensional fixed effects
- Instrumental variables (2SLS) using spatially lagged GTI and government fractionalization
- Robustness checks: alternative terrorism indicators, sample restrictions, non-linearity tests, placebo tests
- Heterogeneity analysis across South–South, South–North, and North–North migration corridors

## Citation

```bibtex
@article{foubert2024migration,
  title={Global migration and the role of terrorist attacks},
  author={Foubert, Killian and Ruyssen, Ilse},
  journal={Journal of Economic Behavior and Organization},
  volume={220},
  pages={507--530},
  year={2024},
  publisher={Elsevier},
  doi={10.1016/j.jebo.2024.02.022}
}
```

## Authors

- **Killian Foubert** — Ghent University / UNU-CRIS
- **Ilse Ruyssen** — Ghent University / UNU-CRIS
