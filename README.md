# RVXL-FT
RVX Light (Without MUL) Fault Tolerant

Implementação de técnicas de tolerância a falhas no RVX (ECC nas memórias, TMR nos FFs),
injeção de falhas no ECC via DFT, e fluxo completo (lógico + físico) em TSMC 65 nm com
memórias compiladas.

## Organização

```
rvxl-ft/
├── rtl/
│   ├── rvx/              RTL do RVX (baseline, origem: fluxo TSMC65 do Gustavo)
│   │   ├── core/         pipeline, decoder, ALU, MDU (Zmmul), CSR, register file
│   │   ├── interconnect/ barramento
│   │   ├── memory/       TCM (comportamental) e bootloader ROM
│   │   ├── peripherals/  GPIO, I2C, SPI, timer, UART
│   │   ├── rvx.v         top lógico (sem pads)
│   │   └── rvx_constants.vh
│   ├── pads/tsmc65/      top_pad_rvx.v (anel de pads TSMC65; parâmetros do SoC)
│   └── ft_ref/           referência ECC (rvx_mul_ft/rtl_ft); NÃO entra na síntese
├── tb/
│   ├── models/           spi_mem_emu.v (modelo de flash SPI, só simulação)
│   ├── ft_ref/           TOP_PAD_tb.v (testbench da versão ECC de referência)
│   └── rvx_mul/          testbenches de periféricos do rvx_mul upstream
├── flow/tsmc65/
│   ├── _setup/setup.tcl  caminhos do projeto, RTL e PDK
│   ├── 2_synthesis/      Design Compiler  (./run_dc.sh)
│   ├── 4_layout/         IC Compiler II   (./run_icc2.sh) — ainda configurado p/ IHP130
│   ├── _lib_prep/        scripts lc_shell/lm_shell usados para gerar os NDM (referência)
│   └── out_data/         saídas (ignorado no git)
└── docs/
    ├── rtl_map.md        de onde vem cada RTL e como as versões se relacionam
    └── baseline_gustavo_syn/  relatórios da síntese original (referência)
```

## Configuração do SoC

Parâmetros em `rtl/pads/tsmc65/top_pad_rvx.v`:

| Parâmetro           | Valor | Observação                                     |
|---------------------|-------|------------------------------------------------|
| `TCM_SIZE_IN_BYTES` | 1024  | TCM comportamental (vira FFs na síntese)       |
| `GPIO_WIDTH`        | 8     |                                                |
| `ENABLE_ZMMUL`      | 1     | 1 = com multiplicador; 0 = RVX "light"         |

## Rodando

```bash
cd flow/tsmc65/2_synthesis && ./run_dc.sh     # síntese lógica
cd flow/tsmc65/4_layout    && ./run_icc2.sh   # P&R (pendente: portar setup para TSMC65)
```

## Estado

- [x] RTL baseline + fluxo de síntese TSMC65 organizado
- [ ] Portar `4_layout` para NDM/tech/TLU+ TSMC65 e validar NDMs
- [ ] Substituir TCM comportamental por SRAM compilada (TSMC65 memory compiler)
- [ ] Versão sem MUL (`ENABLE_ZMMUL=0`)
- [ ] ECC nas memórias, TMR nos FFs
- [ ] Injeção de falhas no ECC via DFT
