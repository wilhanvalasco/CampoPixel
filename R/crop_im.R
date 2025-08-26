#' Recorte interativo por polígono em imagem RGB
#'
#' Esta função permite o recorte interativo de uma região poligonal sobre uma imagem RGB.
#' O usuário define os vértices com cliques do mouse, e a função retorna a imagem recortada.
#'
#' @param x Objeto de imagem RGB (classe `Image`) ou caminho para o arquivo.
#' @param display.it Lógico. Se `TRUE`, exibe o recorte ao final. Padrão: `TRUE`.
#' @param n_points Número de pontos (vértices) a serem definidos interativamente. Mínimo: 3.
#'
#' @return
#' Uma imagem RGB recortada com base no polígono definido.
#'
#' @details
#' - A máscara do polígono é criada com algoritmo de "ray casting".
#' - O recorte corresponde à menor caixa delimitadora (bounding box) que contém o polígono.
#' - A função requer ambiente gráfico e interação com o usuário via mouse.
#'
#' @importFrom EBImage readImage display getFrame Image
#' @importFrom graphics locator polygon rect par
#' @importFrom grDevices dev.flush
#'
#' @examples
#' \donttest{
#' # Carregar imagem
#' img <- EBImage::readImage(system.file("images", "sample.png", package = "EBImage"))
#'
#' # Realizar recorte com 5 pontos
#' recorte <- crop_im(img, n_points = 5, display.it = TRUE)
#'
#' # Exibir resultado
#' EBImage::display(recorte, method = "raster")
#' }
#'
#' @export
crop_im <- function(x, display.it = TRUE, n_points = 4) {
  if (!requireNamespace("EBImage", quietly = TRUE)) {
    stop("Pacote 'EBImage' é necessário. Instale com BiocManager::install('EBImage').")
  }
  if (n_points < 3) stop("'n_points' deve ser >= 3.")

  # ---- carregar imagem ----
  if (inherits(x, "Image")) {
    img <- x
  } else if (is.character(x) && file.exists(x)) {
    img <- EBImage::readImage(x)
    if (EBImage::numberOfFrames(img) > 1) img <- EBImage::getFrame(img, 1)
  } else {
    stop("Forneça um EBImage::Image ou um caminho de arquivo existente.")
  }

  # garantir 3 canais (RGB)
  if (length(dim(img)) == 2) {
    g <- EBImage::imageData(img)
    img <- EBImage::rgbImage(g, g, g)
  } else if (dim(img)[3] > 3) {
    img <- img[,,1:3]
  }
  EBImage::colorMode(img) <- EBImage::Color

  w <- dim(img)[1]; h <- dim(img)[2]

  # ---- helpers ----
  polygon_area <- function(x, y) {
    n <- length(x)
    s <- sum(x[-1] * y[-n] - x[-n] * y[-1]) + (x[n] * y[1] - x[1] * y[n])
    abs(s) / 2
  }

  pip_vec <- function(px, py, vx, vy) {
    n <- length(vx)
    inside <- rep(FALSE, length(px))
    j <- n; eps <- 1e-12
    for (i in seq_len(n)) {
      xi <- vx[i]; yi <- vy[i]; xj <- vx[j]; yj <- vy[j]
      cruz <- ((yi > py) != (yj > py)) &
        (px < (xj - xi) * (py - yi) / (yj - yi + eps) + xi)
      inside <- xor(inside, cruz)
      j <- i
    }
    inside
  }

  # ---- coleta interativa ----
  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op), add = TRUE)

  EBImage::display(img, method = "raster")
  usr <- graphics::par("usr")

  redraw <- function(pts_user) {
    EBImage::display(img, method = "raster")
    if (nrow(pts_user) > 0) {
      graphics::points(pts_user$x, pts_user$y, pch = 19, cex = 1.1)
      if (nrow(pts_user) > 1) graphics::lines(pts_user$x, pts_user$y, lwd = 2)
    }
  }

  to_pixel <- function(xu, yu, usr, w, h) {
    xpx <- (xu - usr[1]) / (usr[2] - usr[1]) * (w - 1) + 1
    if (usr[4] < usr[3]) {
      ypx <- (yu - usr[4]) / (usr[3] - usr[4]) * (h - 1) + 1
    } else {
      ypx <- (yu - usr[3]) / (usr[4] - usr[3]) * (h - 1) + 1
    }
    cbind(x = xpx, y = ypx)
  }

  pts_user <- data.frame(x = numeric(0), y = numeric(0))
  for (i in seq_len(n_points)) {
    pt <- graphics::locator(1)
    if (is.null(pt)) stop("Coleta interrompida: ponto não selecionado.")
    pts_user <- rbind(pts_user, data.frame(x = pt$x, y = pt$y))
    redraw(pts_user)
  }
  # fecha visualmente
  graphics::lines(c(pts_user$x, pts_user$x[1]),
                  c(pts_user$y, pts_user$y[1]), lwd = 2, lty = 2)

  # coords em pixels
  px <- to_pixel(pts_user$x, pts_user$y, usr, w, h)
  coords <- data.frame(x = px[, "x"], y = px[, "y"])

  # valida polígono
  if (polygon_area(coords$x, coords$y) <= 0) {
    stop("Os pontos não formam um polígono válido.")
  }

  # ---- máscara poligonal no tamanho da imagem ----
  gx <- rep(1:w, times = h)
  gy <- rep(1:h, each = w)
  inside <- pip_vec(gx, gy, coords$x, coords$y)
  mask <- matrix(as.numeric(inside), nrow = w, ncol = h)  # [x,y]

  # aplica máscara por canal (RGB)
  imagem <- img
  for (k in 1:dim(imagem)[3]) {
    imagem[,,k] <- img[,,k] * mask
  }

  # ---- recorte ao bounding box ----
  x_min <- max(1, floor(min(coords$x))); x_max <- min(w, ceiling(max(coords$x)))
  y_min <- max(1, floor(min(coords$y))); y_max <- min(h, ceiling(max(coords$y)))
  imagem <- imagem[x_min:x_max, y_min:y_max, ]

  # alfa recortado como atributo
  alpha <- EBImage::Image(mask, dim = c(w, h))
  EBImage::colorMode(alpha) <- EBImage::Grayscale
  alpha <- alpha[x_min:x_max, y_min:y_max]
  attr(imagem, "alpha") <- alpha

  if (isTRUE(display.it)) {
    EBImage::display(imagem, method = "raster")
  }
  return(imagem)
}



