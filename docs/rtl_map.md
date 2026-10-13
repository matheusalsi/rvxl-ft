# Mapa dos RTLs do RVX

Levantamento feito em 2026-10-13 comparando, por hash, as cópias em `tsmc65-gustavo/`,
`dft-labs/` e `rvx/`. Há 4 famílias e 7 variantes distintas.

| #  | Variante                 | Onde                                                        | Características |
|----|--------------------------|-------------------------------------------------------------|-----------------|
| A  | RVX upstream             | `rvx/hardware`, `*/source/rvx_no_mul/hardware`              | Arquitetura plana (8 arquivos), sem MDU, sem I2C. |
| B  | rvx_mul "master" (FPGA)  | `*/source/rvx_mul/rtl`                                      | Core modular + MDU + I2C/timer. `ZMMUL=0`, `GPIO=1`, TCM em 0x1000. Desatualizada vs. C. |
| C1 | rvx_mul ASIC — IHP130    | `*/0_synopsys_ihp130_flow/inp_data/source`                  | B evoluída (TCM com `BASE_ADDRESS`, I2C `scl_input`), pads `ixc013_*`. |
| C2 | rvx_mul ASIC — TSMC65    | `tsmc65-gustavo/.../0_synopsys_tsmc65_flow/inp_data/source` | **= C1**, só troca os pads (`PDUW0204SCDG`, `PVDD1CDG`...). **Usada aqui.** |
| C3 | rvx_mul ASIC — SAED32    | `dft-labs/proj/rvx_mul/0_synopsys_saed32_flow`              | `top_pad` próprio, TCM 128 B. |
| C4 | rvx_mul ASIC — SAED32 DFT| `*/1_synopsys_saed32_flow_dft`                              | `rvx.v`/`top_pad` com portas `test_si/se/so/sm`. |
| D  | rvx_mul_ft               | `*/source/rvx_mul_ft/rtl/{rtl_mul,rtl_ft}`                  | `rtl_mul` ≈ C1 + `rvx_pads.v`; `rtl_ft` = versões ECC (core, integer file, CSR, TCM). |

C1–C4 têm core/periféricos/memória idênticos; diferem só em `rvx.v` e `top_pad_rvx.v`.

## O que foi trazido para este repositório

| Destino                 | Origem                                                     |
|-------------------------|------------------------------------------------------------|
| `rtl/rvx/`              | C2 (`inp_data/source`), exceto `top_pad_rvx.v` e `utils/` |
| `rtl/pads/tsmc65/`      | C2 `top_pad_rvx.v`                                         |
| `rtl/ft_ref/`           | D `rtl_ft` (sem `spi_mem_emu.v`, idêntico ao de `tb/models`) |
| `tb/models/`            | C2 `utils/spi_mem_emu.v`                                   |
| `tb/ft_ref/`            | D `rtl_ft/TOP_PAD_tb.v`                                    |
| `tb/rvx_mul/`           | B `tests/testbenches` (escritos para B; podem precisar de ajuste) |
| `flow/tsmc65/`          | scripts de `0_synopsys_tsmc65_flow` (sem NDMs/binários)    |

Não copiado: `_lc_tsmc/`/`_lm_test/`/`libs/` binários (~1,3 GB, NDMs já em
`/pdk/tsmc/TSMC65_u105206/stdlib_u105206/*/TSMCHOME/digital/NDM/`).
