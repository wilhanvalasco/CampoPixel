#' Função para processamento de imagens RGB com segmentação de solo.
#'
#' Esta função processa imagens RGB obtidas por diferentes dispositivos
#' (celular, drone ou satélite) e retorna métricas relacionadas ao índice NDGR
#' (Índice de Diferença Normalizada Verde-Vermelho) e à segmentação do solo exposto.
#'
#' @param imagem Caminho para o arquivo de imagem (formato suportado pelo EBImage) ou
#' um objeto do tipo Image já carregado. A função detecta automaticamente o tipo.
#' @param max_pixels Número máximo de pixels permitido para a imagem
#' (padrão = 5e6). Imagens maiores são redimensionadas proporcionalmente para
#' reduzir o uso de memória e o tempo de processamento.
#' @param angulo Ângulo de rotação aplicado à imagem em graus
#' (padrão = 0, sem rotação). Útil para ajustar a orientação.
#' @param size_filter Tamanho do filtro da mediana (padrão = 5). Valores maiores
#' suavizam mais a imagem.
#'
#' @return Uma lista contendo:
#' \itemize{
#' \item \code{true_color} - Imagem original (sem redimensionamento, rotação ou filtro).
#' \item \code{NDGR} - Matriz do Índice de Diferença Normalizada Verde-Vermelho.
#' \item \code{im_binary} - Imagem binária segmentada com base no NDGR.
#' \item \code{solo_exp} - Porcentagem de solo exposto na imagem (entre 0 e 1).
#' \item \code{rgb_map} - Mapa colorido representando o NDGR segmentado.
#' \item \code{NDGR_medio} - Valor médio do NDGR considerando apenas os pixels segmentados.
#' \item \code{Imagem_final} - Imagem final com sobreposição do gradiente NDGR.
#' }
#'
#' @details
#' A função depende dos seguintes pacotes: EBImage, scales, parallel, abind, grid, grDevices.
#' Esses pacotes são automaticamente carregados ao executar a função.
#'
#' @examples
#' # Carregue a imagem diretamente ou informe o caminho
#' im <- EBImage::readImage(system.file("images", "sample.png", package = "EBImage"))
#'
#' # Execute o processamento (sem redimensionamento e com filtro 3x3)
#' resultado <- process_img(imagem = im, angulo = 0, size_filter = 3)
#'
#' # Visualize a imagem original
#' EBImage::display(resultado$true_color, method = "raster")
#'
#' # Visualize a imagem final com gradiente NDGR
#' EBImage::display(resultado$Imagem_final, method = "raster")
#'
#' # Acesse os resultados:
#' resultado$NDGR # Matriz NDGR
#' resultado$im_binary # Máscara binária do solo exposto
#' resultado$solo_exp # Proporção de solo exposto
#' resultado$rgb_map # Mapa colorido
#' resultado$NDGR_medio # NDGR médio da imagem
#'
#' @export
process_img <- function(imagem, max_pixels = 5e6, angulo = 0, size_filter = 5) {
  if (!require(EBImage)) {
    install.packages("BiocManager")
    BiocManager::install("EBImage")
    library(EBImage)
  }
  if (!require(scales)) install.packages("scales")
  if (!require(parallel)) install.packages("parallel")
  if (!require(abind)) install.packages("abind")
  if (!require(grid)) install.packages("grid")
  if (!require(grDevices)) install.packages("grDevices")

  library(scales)
  library(parallel)
  library(abind)
  library(grid)
  library(grDevices)

  steps <- 8
  pb <- txtProgressBar(min = 0, max = steps, style = 3)

  if (inherits(imagem, "Image")) {
    imagem_coletada <- imagem
  } else if (is.character(imagem) && file.exists(imagem)) {
    cat("Carregando imagem a partir do caminho informado.\n")
    imagem_coletada <- readImage(imagem)

    if (numberOfFrames(imagem_coletada) > 1) {
      imagem_coletada <- getFrame(imagem_coletada, 1)
    }

    if (length(dim(imagem_coletada)) == 3 && dim(imagem_coletada)[3] == 4) {
      imagem_coletada <- imagem_coletada[,,1:3]
    }
  } else {
    stop("O argumento 'imagem' deve ser um objeto 'Image' ou um caminho de arquivo válido.")
  }

  img_list <- list()
  img_list$true_color <- imagem_coletada
  setTxtProgressBar(pb, 1)

  total_pixels <- prod(dim(imagem_coletada))
  if (total_pixels > max_pixels) {
    fator <- sqrt(max_pixels / total_pixels)
    imagem_coletada <- resize(imagem_coletada, w = dim(imagem_coletada)[2] * fator, h = dim(imagem_coletada)[1] * fator)
    cat(sprintf("\nImagem redimensionada para:\n%dx%d\n", dim(imagem_coletada)[2], dim(imagem_coletada)[1]))
  }

  if (dim(imagem_coletada)[1] > dim(imagem_coletada)[2]) {
    imagem_coletada <- rotate(imagem_coletada, angle = 90)
  }
  imagem_coletada <- medianFilter(imagem_coletada, size = size_filter)

  R <- imagem_coletada[,,1]
  G <- imagem_coletada[,,2]
  denom <- R + G
  denom[denom == 0] <- NA
  NDGR <- (G - R) / denom
  img_list$NDGR <- NDGR
  setTxtProgressBar(pb, 2)

  NDGR_gray <- channel(NDGR, "gray")
  limiar <- otsu(NDGR_gray, range = c(-2, 2))
  seg <- NDGR_gray > limiar
  seg[seg == 0] <- NA
  img_list$im_binary <- seg

  total_pix <- sum(!is.na(seg)) + sum(is.na(seg))
  solo_pix <- sum(is.na(seg))
  img_list$solo_exp <- solo_pix / total_pix

  setTxtProgressBar(pb, 3)

  seg_array <- as.array(seg)
  imagem_array <- as.array(imagem_coletada)
  imagem_segmentada <- imagem_array
  for (i in 1:3) {
    channel <- imagem_array[,,i]
    channel[is.na(seg_array)] <- 0
    imagem_segmentada[,,i] <- channel
  }
  imagem_segmentada <- Image(imagem_segmentada, colormode = Color)
  setTxtProgressBar(pb, 4)

  R2 <- imagem_segmentada[,,1]
  G2 <- imagem_segmentada[,,2]
  denom2 <- G2 + R2
  denom2[denom2 == 0] <- NA
  NDGR2 <- (G2 - R2) / denom2

  ndgr_vals <- as.array(NDGR2)
  mask <- is.finite(ndgr_vals)

  red   <- matrix(NA, nrow = dim(ndgr_vals)[1], ncol = dim(ndgr_vals)[2])
  green <- matrix(NA, nrow = dim(ndgr_vals)[1], ncol = dim(ndgr_vals)[2])
  blue  <- matrix(NA, nrow = dim(ndgr_vals)[1], ncol = dim(ndgr_vals)[2])

  scaled_vals <- (ndgr_vals[mask] + 1) / 2

  custom_palette <- colorRamp(c("darkred", "red", "yellow", "orange", "lightgreen", "darkgreen", "blue", "darkblue"))
  gradient_colors <- custom_palette(scaled_vals)

  red[mask] <- gradient_colors[,1] / 255
  green[mask] <- gradient_colors[,2] / 255
  blue[mask] <- gradient_colors[,3] / 255

  rgb_map <- rgbImage(red = red, green = green, blue = blue)
  img_list$rgb_map <- rgb_map
  setTxtProgressBar(pb, 5)

  NDGR_m <- mean(ndgr_vals[mask], na.rm = TRUE)
  img_list$NDGR_medio <- NDGR_m
  setTxtProgressBar(pb, 6)

  overlay <- as.array(imagem_coletada)
  overlay[,,1][mask] <- red[mask]
  overlay[,,2][mask] <- green[mask]
  overlay[,,3][mask] <- blue[mask]
  overlay_image <- Image(overlay, colormode = Color)
  combined_image <- overlay_image
  img_list$Imagem_final <- combined_image
  setTxtProgressBar(pb, 7)

  if (dim(combined_image)[1] < dim(combined_image)[2]) {
    combined_image <- rotate(combined_image, angle = angulo)
  }
  display(combined_image, method = "raster")

  grid.text(
    label = sprintf("SOLO EXPOSTO: %.1f%%", img_list$solo_exp * 100),
    x = unit(0.985, "npc"),
    y = unit(0.96, "npc"),
    just = c("right", "top"),
    gp = gpar(col = "black", fontsize = 10, fontface = "bold")
  )
  grid.text(
    label = sprintf("NDGR: %.2f", NDGR_m),
    x = unit(0.985, "npc"),
    y = unit(0.925, "npc"),
    just = c("right", "top"),
    gp = gpar(col = "black", fontsize = 10, fontface = "bold")
  )

  pal <- grDevices::colorRampPalette(c("darkred", "red", "yellow", "orange", "lightgreen", "darkgreen", "blue", "darkblue"))(100)
  bar_width <- unit(0.25, "npc")
  bar_height <- unit(0.02, "npc")
  x_offset <- unit(0.73, "npc")
  y_offset <- unit(0.88, "npc")

  pushViewport(viewport(x = x_offset, y = y_offset, width = bar_width, height = bar_height, just = c("left", "bottom")))
  n <- length(pal)
  for (i in seq_len(n)) {
    grid.rect(x = unit(i / n, "npc"),
              y = unit(0.5, "npc"),
              width = unit(1 / n, "npc"),
              height = unit(1, "npc"),
              gp = gpar(col = NA, fill = pal[i]),
              just = c("center", "center"))
  }
  pos_marker <- (NDGR_m + 1) / 2
  pos_marker <- max(min(pos_marker, 1), 0)
  grid.lines(x = unit(c(pos_marker, pos_marker), "npc"),
             y = unit(c(0, 1), "npc"),
             gp = gpar(col = "white", lwd = 2))
  popViewport()

  setTxtProgressBar(pb, 8)
  close(pb)
  message("Processamento concluído.")
  return(img_list)
}

