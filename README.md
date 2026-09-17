# 🏎️ GPX → CarSim Track Builder

**Ferramenta MATLAB para converter arquivos de GPS (.gpx) em dados de pista tridimensionais compatíveis com o CarSim.**

Desenvolvido pelo **Subsistema de Performance** da equipe FSAE **EESC-USP Tupã**.

---

## 📋 Sobre

Este projeto resolve um problema recorrente na equipe: a falta de um método preciso, científico e reprodutível para mapear pistas reais e importá-las no software de dinâmica veicular **CarSim**. Anteriormente, a geometria das curvas era estimada visualmente (usando Paint e métodos empíricos) — agora, o processo é 100% automatizado a partir de coordenadas GPS.

O software recebe um arquivo `.gpx` (padrão de intercâmbio de dados GPS), processa as coordenadas geodésicas (latitude, longitude, altitude) e cria uma pasta exclusiva dentro de `output/` (no formato `<nome_da_pista>_<AAAA-MM-DD_HH-MM-SS>/`) contendo:

| Arquivo de saída | Conteúdo | Destino no CarSim |
|---|---|---|
| `carsim_rdedges.csv` / `rdedges.csv` | $X$ (m), $Y$ (m), $Z$ (m), Station (m) [Cabeçalho `0, 1, 2, 3`] | Road → 3D Surface / X-Y-Z Coordinates of Edges / Reference Line |
| `carsim_xyz.csv` | $X$ (m), $Y$ (m), $Z$ (m) [Cabeçalho `0, 1, 2`] | Road → X-Y-Z Coordinates (3 coordenadas) |
| `elevation.csv` | Station (m) × Elevação (m) | Road → Elevation (referência / validação) |
| `grade.csv` | Station (m) × Inclinação (%) | Road → Elevation (alternativa) |
| `track_data.mat` | Struct completa do MATLAB | Análise offline / telemetria / scripts |
| `track_diagnostics.png` | Imagem com 6 gráficos de diagnóstico | Registro visual e validação técnica |

> **Nota sobre Coordenadas 3D e Curvatura:** Versões anteriores do fluxo de trabalho exportavam uma tabela separada de curvatura horizontal (`carsim_curvature.csv`). Contudo, o CarSim possui suporte nativo à importação direta de coordenadas espaciais 3D através da tela **Road: 3D Surface (X-Y-Z Coordinates of Edges / Reference Line)** utilizando o formato `carsim_rdedges.csv` (cabeçalho `0, 1, 2, 3`). O próprio CarSim calcula a curvatura horizontal, a direção tangencial e a elevação de forma contínua e unificada, tornando a tabela de curvatura desnecessária e eliminando discrepâncias numéricas entre eixos.

---

## 🚀 Como Usar

### 1. Obtenha o arquivo GPX da pista

Desenhe o traçado da pista clicando nos pontos ao longo do percurso e exporte como `.gpx`.

> **Recomendação:** Recomendamos fortemente o uso do site **[plotaroute.com](https://www.plotaroute.com/)** (ferramenta *Create a Route*). Ele é muito mais fácil e intuitivo para traçados de Fórmula SAE (estacionamentos, kartódromos e pátios de teste).

### 2. Execute no MATLAB

No console do MATLAB, execute:

```matlab
gpx_to_carsim
```

Uma janela de seleção de arquivo será aberta. Selecione o arquivo `.gpx` e o script executará todo o processamento automaticamente.

### 3. Importe no CarSim

1. No CarSim, acesse o menu de pistas: **Road: 3D Surface (X-Y-Z Coordinates of Edges)** ou **Road: Centerline & Edges (X-Y-Z Coordinates)**.
2. Importe ou copie e cole os dados do arquivo `carsim_rdedges.csv` (ou `rdedges.csv`). O cabeçalho `0, 1, 2, 3` mapeia diretamente as colunas $X$, $Y$, $Z$ e $S$ (Station).
3. O CarSim construirá automaticamente a pista 3D, calculando o traçado, a curvatura e a elevação.
4. Ajuste a largura da pista (*width*, tipicamente 3 metros para FSAE) e o coeficiente de atrito ($\mu$).

---

## 📐 O que o Software Calcula

1. **Conversão Geodésica** — Converte (latitude, longitude, altitude) para coordenadas cartesianas locais ($X, Y, Z$) em metros usando a aproximação de Terra plana (*flat-Earth*).

2. **Station $S$** — Distância acumulada ao longo da linha de centro da pista (variável independente fundamental do CarSim).

3. **Bordas da Pista (RdEdges $X, Y, Z, S$)** — Formatação exata com cabeçalho `0, 1, 2, 3` para geração imediata da superfície 3D no CarSim.

4. **Curvatura $\kappa(S)$ e Ângulo de Direção** — Calculados analiticamente para o gráfico de diagnóstico e validação técnica:

$$\kappa = \frac{X' \cdot Y'' - Y' \cdot X''}{(X'^2 + Y'^2)^{3/2}}$$

   - $\kappa > 0 \rightarrow$ curva para a esquerda
   - $\kappa < 0 \rightarrow$ curva para a direita

5. **Inclinação Longitudinal (*Grade*)** — Inclinação em \%, obtida da derivada da elevação em relação à Station.

6. **Filtro de Suavização** — Média móvel aplicada nas coordenadas espaciais para atenuar o ruído característico do GPS antes do cálculo de derivadas.

---

## 📁 Estrutura do Projeto

```
performance/
├── gpx_to_carsim.m            % Script principal — execute este
├── parseGPX.m                 % Parser XML de arquivos .gpx
├── geo2local.m                % Conversão geodésica → cartesiana local
├── computeTrackGeometry.m     % Motor de cálculo (Station, curvatura, grade)
├── plotTrackDiagnostics.m     % Geração dos 6 gráficos de diagnóstico
├── guia_software_pistas.tex   % Documentação completa em LaTeX
├── guia_software_pistas.pdf   % Manual compilado em PDF
└── output/                    % Gerada automaticamente
    └── <pista>_<timestamp>/   % Pasta exclusiva por execução
        ├── carsim_rdedges.csv % Tabela 3D + Station para o CarSim (0, 1, 2, 3)
        ├── rdedges.csv        % Cópia idêntica para conveniência
        ├── carsim_xyz.csv     % Coordenadas 3D (0, 1, 2)
        ├── elevation.csv      % Station vs Elevação
        ├── grade.csv          % Station vs Inclinação (%)
        ├── track_data.mat     % Struct completa do MATLAB
        └── track_diagnostics.png % Imagem dos gráficos de diagnóstico
```

---

## ⚙️ Configuração

O único parâmetro ajustável pelo usuário encontra-se no início de `gpx_to_carsim.m`:

```matlab
SMOOTH_WINDOW = 5;  % Tamanho da janela de média móvel (em pontos)
```

| Valor | Efeito |
|---|---|
| 3 | Preserva curvas muito fechadas (*hairpins*), porém mais suscetível a ruídos |
| **5** | **Equilíbrio padrão recomendado** |
| 7+ | Curvas bastante suaves, pode arredondar vértices fechados |

---

## 📊 Gráficos de Diagnóstico

O script gera automaticamente uma figura com 6 subplots (salva como `track_diagnostics.png` na pasta da pista):

| Painel | Descrição |
|---|---|
| **Mapa XY** | Vista superior com trajetória bruta vs suavizada e setas de sentido |
| **Vista 3D** | Pista no espaço tridimensional com gradiente de cor por elevação |
| **Curvatura vs Station** | Perfil de curvatura $\kappa$ com raio de curva $R$ no eixo secundário |
| **Elevação vs Station** | Perfil longitudinal de altitude e variação $\Delta Z$ |
| **Grade vs Station** | Inclinação longitudinal (%) ao longo do percurso |
| **Heading vs Station** | Ângulo de direção da trajetória (em graus) |

---

## 📝 Requisitos

- **MATLAB** R2020b ou superior (não requer toolboxes pagas adicionais)
- **CarSim** (para simulação veicular da pista)
- Navegador web (para acessar o [plotaroute.com](https://www.plotaroute.com/) ou [gpx.studio](https://gpx.studio/))

---

## 📖 Documentação Completa

O manual detalhado com formulação matemática, equações, boas práticas de modelagem e guia de *troubleshooting* está disponível nos arquivos:

* 📄 Código-fonte: [`guia_software_pistas.tex`](guia_software_pistas.tex)
* 📕 Documento PDF compilado: [`guia_software_pistas.pdf`](guia_software_pistas.pdf)

---

## 👤 Autor

**Eduardo Yumoto Carvalheira** — Gerente de Performance

Equipe FSAE EESC-USP Tupã | São Carlos, SP
