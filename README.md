# 🏎️ GPX → CarSim Track Builder

**Ferramenta MATLAB para converter arquivos GPS (.gpx) em dados de pista compatíveis com o CarSim.**

Desenvolvido pelo **Subsistema de Performance** da equipe FSAE **EESC-USP Tupã**.

---

## 📋 Sobre

Este projeto resolve um problema recorrente na equipe: a falta de um método preciso e reprodutível para mapear pistas reais e importá-las no software de simulação de dinâmica veicular **CarSim**. Anteriormente, a geometria das curvas era estimada visualmente — agora, o processo é automatizado a partir de coordenadas GPS.

O software recebe um arquivo `.gpx` (padrão de intercâmbio de dados GPS), processa as coordenadas geodésicas (latitude, longitude, altitude), e exporta três tabelas `.csv` prontas para serem inseridas no CarSim:

| Arquivo de saída | Conteúdo | Destino no CarSim |
|---|---|---|
| `carsim_curvature.csv` | Station (m) × Curvatura (1/m) | Road → Path (VS Reference Path) |
| `carsim_elevation.csv` | Station (m) × Elevação (m) | Road → Elevation |
| `carsim_grade.csv` | Station (m) × Inclinação (%) | Road → Elevation (alternativa) |

---

## 🚀 Como usar

### 1. Obtenha o arquivo GPX

Acesse [gpx.studio](https://gpx.studio/) e desenhe o traçado da pista clicando nos pontos ao longo do percurso. Exporte como `.gpx`.

### 2. Execute no MATLAB

```matlab
gpx_to_carsim
```

Uma janela de seleção de arquivo será aberta. Selecione o `.gpx` e o script fará todo o processamento automaticamente.

### 3. Importe no CarSim

Copie os dados dos CSVs gerados na pasta `output/` para as telas de **Road → Path** (curvatura) e **Road → Elevation** (elevação) do CarSim.

---

## 📐 O que o software calcula

1. **Conversão geodésica** — Converte (lat, lon, ele) para coordenadas cartesianas locais (X, Y, Z) em metros, usando aproximação de Terra plana.

2. **Station S** — Distância acumulada ao longo do traçado (variável independente do CarSim).

3. **Curvatura κ(S)** — Calculada pela fórmula paramétrica:

$$\kappa = \frac{X' \cdot Y'' - Y' \cdot X''}{(X'^2 + Y'^2)^{3/2}}$$

   - κ > 0 → curva para a esquerda
   - κ < 0 → curva para a direita

4. **Grade (S)** — Inclinação longitudinal em %, calculada a partir da variação de elevação.

5. **Suavização** — Filtro de média móvel para reduzir o ruído inerente ao GPS antes de calcular derivadas.

---

## 📁 Estrutura do projeto

```
performance/
├── gpx_to_carsim.m            # Script principal — execute este
├── parseGPX.m                 # Parser XML do arquivo .gpx
├── geo2local.m                # Conversão geodésica → cartesiana local
├── computeTrackGeometry.m     # Cálculos de Station, curvatura e grade
├── plotTrackDiagnostics.m     # Geração dos 6 gráficos de diagnóstico
├── guia_software_pistas.tex   # Documentação completa (LaTeX)
└── output/                    # Gerada automaticamente
    ├── carsim_curvature.csv
    ├── carsim_elevation.csv
    ├── carsim_grade.csv
    └── track_data.mat
```

---

## ⚙️ Configuração

O único parâmetro ajustável pelo usuário está no topo de `gpx_to_carsim.m`:

```matlab
SMOOTH_WINDOW = 5;  % Janela de suavização (média móvel, em pontos)
```

| Valor | Efeito |
|-------|--------|
| 3 | Preserva curvas fechadas (hairpins), porém mais ruidoso |
| **5** | **Equilíbrio recomendado** |
| 7+ | Curvas muito suaves, pode achatar hairpins |

---

## 📊 Gráficos de diagnóstico

O script gera automaticamente uma figura com 6 painéis para validação visual:

| Painel | O que mostra |
|--------|--------------|
| Mapa XY | Vista superior com trajetória bruta vs suavizada |
| Vista 3D | Pista em 3D colorida por elevação |
| Curvatura vs Station | Perfil de curvatura com raio no eixo secundário |
| Elevação vs Station | Perfil longitudinal de elevação |
| Grade vs Station | Inclinação (%) ao longo da pista |
| Heading vs Station | Ângulo de direção ao longo do traçado |

---

## 📝 Requisitos

- **MATLAB** R2020b ou superior (sem toolboxes adicionais)
- **CarSim** (para importação dos dados)
- Navegador web (para acessar [gpx.studio](https://gpx.studio/))

---

## 📖 Documentação

A documentação completa com fundamentação teórica, equações, passo a passo detalhado e guia de troubleshooting está disponível no arquivo LaTeX:

📄 [`guia_software_pistas.tex`](guia_software_pistas.tex)

---

## 👤 Autor

**Eduardo Yumoto Carvalheira** — Gerente de Performance

Equipe FSAE EESC-USP Tupã | São Carlos, SP
