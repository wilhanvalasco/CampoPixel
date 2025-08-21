#' Reduz a imagem por um percentual (downscale)
#'
#' @description
#' Redimensiona a imagem para o percentual informado (mantendo proporção).
#' Ex.: \code{percentual = 50} reduz para 50% da largura e altura.
#'
#' @param x Objeto \code{EBImage::Image} ou caminho para arquivo de imagem.
#' @param percentual (\code{numeric}) Percentual desejado (1 a 100).
#'
#' @return Um \code{EBImage::Image} redimensionado. Atributos úteis:
#' \itemize{
#'   \item \code{attr(img, "scale_factor")} (fator aplicado, ex.: 0.5)
#'   \item \code{attr(img, "orig_dim")} e \code{attr(img, "new_dim")}
#'   \item Se houver \code{attr(x, "alpha")}, ele é redimensionado e reaplicado.
#' }
#'
#' @examples
#' \donttest{
#' # im <- EBImage::readImage("foto.jpg")
#' # im_small <- resize_im(im, 50)  # 50% do tamanho
#' # EBImage::display(im_small, method = "raster")
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
