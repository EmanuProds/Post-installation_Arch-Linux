# Maintainer: Your Name <your.email@example.com>
pkgname=archpi-configurator
pkgver=0.2.0 # Incrementada a versão para refletir a reescrita em Python
pkgrel=1
pkgdesc="A graphical configurator for Arch Linux post-installation scripts (archPI) - Python version."
arch=('any')
url="<URL_DO_SEU_REPOSITORIO_GIT_SE_HOUVER>"
license=('GPL3') # Ou a licença que você escolher
depends=('python-gobject' 'gtk4' 'libadwaita') # Dependências Python
makedepends=()

# Para desenvolvimento local, você pode comentar as linhas source e sha256sums
# e descomentar a seção prepare() para usar os arquivos locais.
# Exemplo de source para um tarball:
# source=("$pkgname-$pkgver.tar.gz")
# sha256sums=('SKIP') # Substituir por 'md5sum' ou 'sha256sum' do tarball

# Se os arquivos estão no mesmo diretório do PKGBUILD (para teste local):
source=('main_python.py'
        'archPI.sh'
        'archPI-personal.sh'
        'archpi-configurator.desktop'
        'data/archPI.sh/add_locales_content.txt' # Listar todos os arquivos de dados explicitamente
        'data/archPI.sh/install_themes_wallpapers_extensions_pacman.txt'
        'data/archPI.sh/install_themes_wallpapers_extensions_yay.txt'
        'data/archPI.sh/install_yay_pacman_dependencies.txt'
        'data/archPI.sh/install_zsh_terminal_customizations_cargo.txt'
        'data/archPI.sh/install_zsh_terminal_customizations_pacman.txt'
        'data/archPI.sh/install_zsh_terminal_customizations_yay.txt'
        'data/archPI.sh/remove_startup_beep_content.txt'
        'data/archPI-personal.sh/add_locales_content.txt'
        'data/archPI-personal.sh/install_apps_flatpak.txt'
        'data/archPI-personal.sh/install_apps_pacman.txt'
        'data/archPI-personal.sh/install_apps_yay.txt'
        'data/archPI-personal.sh/remove_startup_beep_content.txt'
        # Adicione quaisquer outros arquivos de dados aqui
       )
noextract=() # Para que os arquivos acima não sejam extraídos se source for local
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP') # 'SKIP' para desenvolvimento local

# Se usando um tarball que extrai para um diretório (ex: $pkgname-$pkgver),
# a função build() ou prepare() pode ser usada para navegar até ele.
# Se os arquivos são copiados diretamente para $srcdir (como no array source acima),
# não precisamos de build() para este tipo de projeto simples.

package() {
  # Diretório de origem dos arquivos (onde o PKGBUILD está e onde os arquivos fonte são colocados)
  # Se usando um tarball, seria algo como cd "$srcdir/$pkgname-$pkgver" ou similar.
  # Para a estrutura de source array acima, os arquivos estão em $srcdir.
  # cd "$srcdir" # Geralmente já é o diretório atual aqui

  # Criar diretórios de instalação
  install -d "$pkgdir/usr/share/$pkgname"
  install -d "$pkgdir/usr/share/$pkgname/data/archPI.sh"
  install -d "$pkgdir/usr/share/$pkgname/data/archPI-personal.sh"
  install -d "$pkgdir/usr/share/applications"
  # install -d "$pkgdir/usr/share/icons/hicolor/scalable/apps" # Para ícone SVG

  # Copiar arquivos da aplicação
  install -Dm644 main_python.py "$pkgdir/usr/share/$pkgname/main_python.py"
  install -Dm755 archPI.sh "$pkgdir/usr/share/$pkgname/archPI.sh"
  install -Dm755 archPI-personal.sh "$pkgdir/usr/share/$pkgname/archPI-personal.sh"

  # Copiar arquivos de dados
  # É mais seguro copiar arquivos individualmente ou usar find para mais controle
  # do que cp -r data/*, mas para este caso, cp -r é mais simples se a estrutura for conhecida.
  # No entanto, como listamos explicitamente no array source, podemos copiá-los diretamente.

  local data_archpi_sh_dir="$pkgdir/usr/share/$pkgname/data/archPI.sh"
  install -Dm644 data/archPI.sh/add_locales_content.txt "$data_archpi_sh_dir/add_locales_content.txt"
  install -Dm644 data/archPI.sh/install_themes_wallpapers_extensions_pacman.txt "$data_archpi_sh_dir/install_themes_wallpapers_extensions_pacman.txt"
  install -Dm644 data/archPI.sh/install_themes_wallpapers_extensions_yay.txt "$data_archpi_sh_dir/install_themes_wallpapers_extensions_yay.txt"
  install -Dm644 data/archPI.sh/install_yay_pacman_dependencies.txt "$data_archpi_sh_dir/install_yay_pacman_dependencies.txt"
  install -Dm644 data/archPI.sh/install_zsh_terminal_customizations_cargo.txt "$data_archpi_sh_dir/install_zsh_terminal_customizations_cargo.txt"
  install -Dm644 data/archPI.sh/install_zsh_terminal_customizations_pacman.txt "$data_archpi_sh_dir/install_zsh_terminal_customizations_pacman.txt"
  install -Dm644 data/archPI.sh/install_zsh_terminal_customizations_yay.txt "$data_archpi_sh_dir/install_zsh_terminal_customizations_yay.txt"
  install -Dm644 data/archPI.sh/remove_startup_beep_content.txt "$data_archpi_sh_dir/remove_startup_beep_content.txt"

  local data_archpi_personal_sh_dir="$pkgdir/usr/share/$pkgname/data/archPI-personal.sh"
  install -Dm644 data/archPI-personal.sh/add_locales_content.txt "$data_archpi_personal_sh_dir/add_locales_content.txt"
  install -Dm644 data/archPI-personal.sh/install_apps_flatpak.txt "$data_archpi_personal_sh_dir/install_apps_flatpak.txt"
  install -Dm644 data/archPI-personal.sh/install_apps_pacman.txt "$data_archpi_personal_sh_dir/install_apps_pacman.txt"
  install -Dm644 data/archPI-personal.sh/install_apps_yay.txt "$data_archpi_personal_sh_dir/install_apps_yay.txt"
  install -Dm644 data/archPI-personal.sh/remove_startup_beep_content.txt "$data_archpi_personal_sh_dir/remove_startup_beep_content.txt"

  # Copiar arquivo .desktop e ajustar Exec
  # O arquivo .desktop é referenciado pelo nome que está no array source
  sed "s|Exec=python main_python.py|Exec=python /usr/share/$pkgname/main_python.py|" archpi-configurator.desktop > "$pkgdir/usr/share/applications/$pkgname.desktop"
  chmod 644 "$pkgdir/usr/share/applications/$pkgname.desktop"

  # Exemplo de instalação de ícone
  # install -Dm644 "path/to/icon.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/$pkgname.svg"
}
