<img align="right" src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/logo_campo_pixel.png" width="16%" height="16%">
<h2 align="center">Campo Pixel </h2>
*Uma biblioteca R inteligente que transforma pixels em insights na agricultura.*

O pacote **CampoPixel** tem como objetivo **mapear a saúde das plantas** e o **percentual de solo exposto** a partir de **imagens RGB** capturadas por celulares, drones e satélites.  
Ele oferece um fluxo simples: **carregar → processar → visualizar/quantificar**, com foco em reprodutibilidade e desempenho.

---

<h2 align="center">Captura de imagens em campo </h2>

Para obter bons resultados, priorize **imagens bem iluminadas, nítidas e sem sombras** sobre a área de interesse.

<details>
  <summary><strong>Roteiro prático (clique para expandir)</strong></summary>

- Câmera reta ao solo (perpendicular), sem inclinação.  
- Evitar ângulos >10° que causem distorções.  
- Preferir luz difusa (céu nublado ou com nuvens finas).  
- Evitar sol direto ao meio-dia e sombras sobre a área.  
- Centralizar a cultura/solo, ocupar >80% do quadro.  
- Não incluir pessoas, máquinas ou objetos no fundo.  
- Resolução mínima: 180 PPI; formatos: .jpg, .png, .tif.  
- Padronizar altura (ex.: 1,5 m solo; 0,5 m folhas).  
- Capturar ≥3 imagens por ponto/talhão.  
- Evitar vento forte ou solo encharcado/reflexivo.  
- Nomear arquivos: `data_local_talhao_cultura_rep.jpg`.  
- Organizar por pastas diárias de captura.

</details>

---

<h2 align="center">Exemplo visual de captura </h2>

<p align="center">
  <img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/exemplo.png" alt="Exemplo de captura" width="72%">
</p>

---

<h2 align="center">Exemplos de aplicação </h2>

A seguir, exemplos que ilustram a diferença entre a imagem original e o resultado após processamento pelo **CampoPixel**.

<table>
  <tr>
    <td align="center" width="50%">
      <img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/campo1.jpeg" alt="Imagem RGB original" width="96%"><br>
      <em>Imagem original (RGB capturada por drone)</em>
    </td>
    <td align="center" width="50%">
      <img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/campo_processado.png" alt="Resultado processado" width="96%"><br>
      <em>Imagem processada (saída gerada pelo pacote)</em>
    </td>
  </tr>
</table>

Essas figuras demonstram como o pacote transforma uma imagem RGB convencional em uma representação segmentada, evidenciando áreas de solo exposto, cobertura vegetal e variações de sanidade foliar.

---

<h2 align="center">Saídas da função `process_im()` </h2>

A função `process_im()` retorna métricas que ajudam a interpretar o estado da vegetação e do solo a partir de imagens RGB.  
As principais saídas são o **NDGR** e o **percentual de solo exposto**.

---

### 1. **NDGR – Normalized Difference Green-Red Index**

O **NDGR** (*Normalized Difference Green-Red Index*) é um índice espectral que mede a diferença relativa entre os canais **verde (G)** e **vermelho (R)** da imagem.  
Sua fórmula é:

\[
NDGR = \frac{G - R}{G + R}
\]

- **G**: intensidade da banda verde.  
- **R**: intensidade da banda vermelha.  

Esse índice destaca áreas com maior presença de verde em relação ao vermelho, permitindo identificar vegetação ativa quando não há disponibilidade de bandas no infravermelho (como NDVI).  
É uma métrica útil em análises de imagens RGB capturadas por drones, câmeras ou satélites de baixa resolução.

Esta é a escala de cores utilizada para o **NDGR**.  

<p align="center">
  <img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/paleta.png" 
       alt="Paleta de cores NDGR" width="50%">
</p>

O índice varia de **-1 a 1**: quanto menor o valor, menor a reflectância associada à vegetação — indicando áreas de solo exposto ou baixa cobertura vegetal.
     
---

### 2. **Solo – Percentual de Solo Exposto**

O indicador **Solo** representa o **percentual de solo exposto** na imagem.  

- Se a saída indicar **60% de solo exposto**, significa que os outros **40% correspondem à vegetação** (ou outros elementos não classificados como solo).  
- O cálculo é realizado por meio de **segmentação da imagem RGB**, em que os pixels são classificados em duas grandes categorias: **solo** e **vegetação**.  
- Após a segmentação, é feita a razão entre o número de pixels classificados como solo e o total da imagem, resultando em um valor percentual.

Esse indicador é fundamental para estudos de **cobertura vegetal, erosão e práticas de manejo agrícola**, pois fornece uma visão quantitativa do quanto da superfície está descoberta.

---

### 3. **Resumo Técnico**

| Saída do `process_im()` | Significado                          | Método de Cálculo                        |
|--------------------------|--------------------------------------|------------------------------------------|
| **NDGR**                 | Índice verde–vermelho normalizado    | \((G - R) / (G + R)\) com bandas RGB     |
| **Solo (%)**             | Percentual de solo exposto           | Segmentação de pixels RGB em solo/vegetação |

---

<h2 align="center">Configurações do `CampoPixel` </h2>
```r
if (!require(devtools)) install.packages("devtools")
devtools::install_github("wilhanvalasco/CampoPixel")
library(CampoPixel)

```

### Funções
```r 
process_img()

Processa uma imagem RGB, calcula índices (ex.: NDGR) e estima métricas como **percentual de solo exposto**, além de gerar artefatos visuais úteis (mapas e sobreposições).
```

```r 
crop_im()

Recorta uma região de interesse para análises locais ou para padronizar áreas entre múltiplas imagens.
```

### Exemplos
  
```r
library(CampoPixel)

# Caminho para a sua imagem:
img_path <- "/caminho/para/sua/imagem.jpg"

# Processamento principal
res <- process_img(file_path = img_path, max_pixels = 5e6, angulo = 0)

# Ajuda e exemplos:
help(process_img)
help(crop_im)
```
---

<h2 align="center">Desenvolvedores </h2>

<table role="presentation" style="width:100%; border-collapse:separate; border-spacing:20px;">
<tr>
<td align="center" width="50%" style="padding:0; vertical-align:top;">
<div style="border-radius:16px; padding:18px 20px; text-align:center; background-image:linear-gradient(#ffffff,#ffffff),linear-gradient(135deg,#4f46e5,#22c55e,#06b6d4); background-origin:border-box; background-clip:padding-box, border-box; border:1px solid transparent; box-shadow:0 8px 24px rgba(2,6,23,.10);">

<img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/wilhan.jpg" 
     alt="Foto de Wilhan Valasco" 
     width="112" height="112"
     style="display:block; margin:0 auto 12px; width:112px; height:112px; border-radius:50%; object-fit:cover; object-position: top; box-shadow:0 0 0 3px #fff, 0 6px 16px rgba(2,6,23,.18); background:#e2e8f0;">

<span style="display:block; font-weight:800; font-size:1.05rem; margin:6px 0 8px; color:#0f172a; letter-spacing:.2px;">Wilhan Valasco</span>
<p style="margin:0 auto 10px; color:#475569; font-size:.95rem; line-height:1.4; max-width:36ch;">Eng. Agrônomo · Me. Prot. Plantas · MBA Gestão · Esp. Data Science · Doutorando Biotecnologia/Biodversidade (IF Goiano).</p>
<a href="mailto:wilhanvalasco@hotmail.com" style="display:inline-block; margin-top:6px; text-decoration:none; font-weight:700; color:#0ea5e9; padding-bottom:2px; border-bottom:1px dashed rgba(14,165,233,.5);">✉️ wilhanvalasco@hotmail.com</a>
</div>
</td>
<td align="center" width="50%" style="padding:0; vertical-align:top;">
<div style="border-radius:16px; padding:18px 20px; text-align:center; background-image:linear-gradient(#ffffff,#ffffff),linear-gradient(135deg,#4f46e5,#22c55e,#06b6d4); background-origin:border-box; background-clip:padding-box, border-box; border:1px solid transparent; box-shadow:0 8px 24px rgba(2,6,23,.10);">
<img src="https://raw.githubusercontent.com/wilhanvalasco/CampoPixel/main/inst/exdata/baida.jpg"
     alt="Foto de Walter Baida" 
     width="112" height="112"
     style="display:block; margin:0 auto 12px; width:112px; height:112px; border-radius:50%; object-fit:cover; object-position: top; box-shadow:0 0 0 3px #fff, 0 6px 16px rgba(2,6,23,.18); background:#e2e8f0;">
<span style="display:block; font-weight:800; font-size:1.05rem; margin:6px 0 8px; color:#0f172a; letter-spacing:.2px;">Walter Baida</span>
<p style="margin:0 auto 10px; color:#475569; font-size:.95rem; line-height:1.4; max-width:36ch;">Eng. Agrônomo · Me. Prot. Plantas · Esp. Bioinsumos · Doutorando Estatística/Biometria (UFV).</p>
<a href="mailto:walterbgc1@gmail.com" style="display:inline-block; margin-top:6px; text-decoration:none; font-weight:700; color:#0ea5e9; padding-bottom:2px; border-bottom:1px dashed rgba(14,165,233,.5);">✉️ walterbgc@gmail.com</a>
</div>
</td>
</tr>
</table>


---
