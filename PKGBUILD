# Maintainer: Your Name <your.email@example.com>
pkgname=archpi-configurator
pkgver=0.1.0
pkgrel=1
pkgdesc="A graphical configurator for Arch Linux post-installation scripts (archPI)."
arch=('any')
url=""
license=('GPL3') # Ou a licença que você escolher
depends=('gtk4' 'libadwaita' 'gjs')
makedepends=()
source=("$pkgname-$pkgver.tar.gz") # Placeholder para um futuro tarball do release
# Alternativamente, para desenvolvimento, pode-se usar source=("$pkgname::git+URL_DO_SEU_REPOSITORIO_GIT#tag=$pkgver")
# Para construir a partir dos arquivos locais sem um tarball ou git repo, você pode listar os arquivos:
# source=('main.js' 'archPI.sh' 'archPI-personal.sh' 'archpi-configurator.desktop' 'data/')

sha256sums=('SKIP') # Adicionar checksums quando tiver o tarball
# Para arquivos locais, use 'SKIP' ou gere com 'updpkgsums'

package() {
  # Se source NÃO cria um subdiretório $pkgname automaticamente:
  # mkdir -p "$srcdir/$pkgname"
  # cp -r "${source[@]}" "$srcdir/$pkgname/" # Copia todos os arquivos listados em source
  # cd "$srcdir/$pkgname"

  # Se source É um tarball que extrai para $pkgname-$pkgver ou similar:
  cd "$srcdir/$pkgname-$pkgver" # Ajuste conforme a estrutura do seu tarball

  # Criar diretórios de instalação
  install -d "$pkgdir/usr/share/$pkgname"
  install -d "$pkgdir/usr/share/$pkgname/data/archPI.sh"
  install -d "$pkgdir/usr/share/$pkgname/data/archPI-personal.sh"
  install -d "$pkgdir/usr/share/applications"
  install -d "$pkgdir/usr/share/icons/hicolor/scalable/apps" # Exemplo para ícone SVG

  # Copiar arquivos da aplicação
  install -Dm644 main.js "$pkgdir/usr/share/$pkgname/main.js"
  install -Dm755 archPI.sh "$pkgdir/usr/share/$pkgname/archPI.sh"
  install -Dm755 archPI-personal.sh "$pkgdir/usr/share/$pkgname/archPI-personal.sh"

  # Copiar diretório de dados recursivamente
  # É importante que a estrutura de 'data' no source corresponda a isso
  cp -r data/archPI.sh/* "$pkgdir/usr/share/$pkgname/data/archPI.sh/"
  cp -r data/archPI-personal.sh/* "$pkgdir/usr/share/$pkgname/data/archPI-personal.sh/"

  # Copiar arquivo .desktop e ajustar Exec
  # O arquivo .desktop deve estar na raiz do source para este caminho funcionar
  sed "s|Exec=gjs main.js|Exec=gjs /usr/share/$pkgname/main.js|" archpi-configurator.desktop > "$pkgdir/usr/share/applications/$pkgname.desktop"
  chmod 644 "$pkgdir/usr/share/applications/$pkgname.desktop"

  # Exemplo de instalação de ícone (se você tiver um archpi-configurator.svg na raiz do source)
  # install -Dm644 "archpi-configurator.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/$pkgname.svg"
}
