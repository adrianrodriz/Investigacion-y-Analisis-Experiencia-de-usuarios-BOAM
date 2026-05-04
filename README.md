## Requisitos para reproducir las visualizaciones de datos de la investigacion

- **R** 4.0 o superior (recomendado 4.3+).
- Paquetes de CRAN:

```r
install.packages(c(
  "readr", "dplyr", "tidyr", "ggplot2", "lubridate",
  "stringr", "wordcloud", "stopwords", "tibble"
))
```

## Cómo ejecutar `opiniones.R`

El script lee el CSV **por ruta relativa** al directorio de trabajo. Debes lanzarlo **desde esta carpeta** (`Proyecto`), donde están el `.R` y el `.csv`.

### Terminal

```bash
cd "/Users/{nombre equipo}/Documents/Proyecto"
Rscript opiniones.R
```

### RStudio / consola R

```r
setwd("/ruta/completa/hasta/Proyecto")  # carpeta que contiene opiniones.R y el CSV
source("opiniones.R")
```

### Salida

- Se imprimen en el dispositivo gráfico por defecto:
  1. **Barras apiladas** por mes (`start_date`) y nivel de la pregunta 7 (satisfacción general).
  2. **Nube de palabras** a partir de los comentarios abiertos (pregunta 8).
  3. **Gráfico de barras horizontales** con el **top 25** de palabras por porcentaje sobre el total de filas del dataset.
- En ejecución por lotes (`Rscript`), R suele volcar las figuras en **`Rplots.pdf`** en el directorio de trabajo actual (la carpeta `Proyecto` si ahí has ejecutado el comando).