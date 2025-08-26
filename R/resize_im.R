#' Redimensionamento proporcional de imagem RGB
#'
#' Reduz a imagem original para uma porcentagem da dimensão, mantendo a proporção entre largura e altura.
#'
#' @param x Objeto de imagem (classe `Image`) ou caminho para o arquivo.
#' @param percentual Valor numérico entre 1 e 100 representando o percentual de escala desejado.
#'
#' @return
#' Uma imagem RGB redimensionada. A função preserva atributos como dimensões originais e fator de escala.
#'
#' @details
#' - A imagem é redimensionada proporcionalmente com base no percentual informado.
#' - Caso o objeto original possua atributos adicionais (como máscara), eles são reescalados junto.
#'
#' @importFrom EBImage readImage resize getFrame Image
#'
#' @examples
#' \donttest{
#' # Carregar imagem
#' img <- readImage(system.file("images", "sample.png", package = "EBImage"))
#'
#' # Reduzir para 40% do tamanho
#' img_red <- resize_im(img, 40)
#'
#' # Exibir imagem resultante
#' display(img_red, method = "raster")
#' }
#'
#' @export
resize_im <- function(x, percentual) {
  if (!requireNamespace("EBImage", quietly = TRUE)) {
    stop("Pacote 'EBImage' é necessário. Instale com BiocManager::install('EBImage').")
  }
  if (!is.numeric(percentual) || length(percentual) != 1L) {
    stop("'percentual' deve ser um número único (1 a 100).")
  }
  if (percentual <= 0 || percentual > 100) {
    stop("'percentual' deve estar no intervalo (0, 100].")
  }

  # Carrega imagem
  if (inherits(x, "Image")) {
    img <- x
  } else if (is.character(x) && file.exists(x)) {
    img <- EBImage::readImage(x)
  } else {
    stop("Forneça um EBImage::Image ou um caminho de arquivo existente.")
  }

  # Usa o primeiro frame (consistência)
  if (EBImage::numberOfFrames(img) > 1) {
    img <- EBImage::getFrame(img, 1)
  }

  d <- dim(img); w <- d[1]; h <- d[2]
  scale <- percentual / 100

  # Se ~100%, retorna original com metadados
  if (scale >= 0.999) {
    attr(img, "scale_factor") <- 1
    attr(img, "orig_dim") <- c(w, h, ifelse(length(d) >= 3, d[3], 1))
    attr(img, "new_dim")  <- attr(img, "orig_dim")
    return(img)
  }

  new_w <- max(1L, as.integer(round(w * scale)))
  new_h <- max(1L, as.integer(round(h * scale)))

  img_small <- EBImage::resize(img, w = new_w, h = new_h)

  # Se a imagem tinha alfa como atributo (ex.: saído do crop_im), redimensiona também
  alpha_attr <- attr(img, "alpha", exact = TRUE)
  if (!is.null(alpha_attr) && inherits(alpha_attr, "Image")) {
    alpha_small <- EBImage::resize(alpha_attr, w = new_w, h = new_h)
    attr(img_small, "alpha") <- alpha_small
  }

  attr(img_small, "scale_factor") <- new_w / w
  attr(img_small, "orig_dim") <- c(w, h, ifelse(length(d) >= 3, d[3], 1))
  attr(img_small, "new_dim")  <- c(new_w, new_h, ifelse(length(dim(img_small)) >= 3, dim(img_small)[3], 1))

  return(img_small)
}
