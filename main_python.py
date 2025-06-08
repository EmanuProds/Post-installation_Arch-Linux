# SPDX-License-Identifier: MIT

import sys
import gi
import os
import subprocess # 1. Importação Adicional

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gio, GLib

APP_ID = 'com.example.ArchPIConfigurator_py'

COMMANDS_BLOCK_DELIMITER_LINE = "#------------------------------------------------------------------------ #"
COMMANDS_BLOCK_START_TEXT = "# Commands (uncomment the ones you want to use)"

EXTERNAL_CONFIGS = {
    'archPI.sh': {
        'install_yay': [{'id': 'pacman_dependencies', 'label': 'Pacman Deps', 'dialogTitle': 'Dependências Pacman do Yay (archPI.sh)', 'file': 'install_yay_pacman_dependencies.txt'}],
        'add_locales': [{'id': 'locales_list', 'label': 'Locales', 'dialogTitle': 'Locales a serem adicionados (archPI.sh)', 'file': 'add_locales_content.txt'}],
        'install_zsh_terminal-customizations': [
            {'id': 'pacman_zsh', 'label': 'Pacman', 'dialogTitle': 'Pacotes Pacman ZSH (archPI.sh)', 'file': 'install_zsh_terminal_customizations_pacman.txt'},
            {'id': 'yay_zsh', 'label': 'Yay', 'dialogTitle': 'Pacotes Yay ZSH (archPI.sh)', 'file': 'install_zsh_terminal_customizations_yay.txt'},
            {'id': 'cargo_zsh', 'label': 'Cargo', 'dialogTitle': 'Pacotes Cargo ZSH (archPI.sh)', 'file': 'install_zsh_terminal_customizations_cargo.txt'}
        ],
        'install_themes_wallpapers_and_extensions': [
            {'id': 'yay_themes', 'label': 'Yay', 'dialogTitle': 'Pacotes Yay Temas (archPI.sh)', 'file': 'install_themes_wallpapers_extensions_yay.txt'},
            {'id': 'pacman_themes', 'label': 'Pacman', 'dialogTitle': 'Pacotes Pacman Temas (archPI.sh)', 'file': 'install_themes_wallpapers_extensions_pacman.txt'}
        ]
    },
    'archPI-personal.sh': {
        'install_apps': [
            {'id': 'flatpak_apps', 'label': 'Flatpak', 'dialogTitle': 'Aplicativos Flatpak (archPI-personal.sh)', 'file': 'install_apps_flatpak.txt'},
            {'id': 'yay_apps', 'label': 'Yay', 'dialogTitle': 'Aplicativos Yay (archPI-personal.sh)', 'file': 'install_apps_yay.txt'},
            {'id': 'pacman_apps', 'label': 'Pacman', 'dialogTitle': 'Aplicativos Pacman (archPI-personal.sh)', 'file': 'install_apps_pacman.txt'}
        ],
        'add_locales': [{'id': 'locales_list_personal', 'label': 'Locales', 'dialogTitle': 'Locales a serem adicionados (archPI-personal.sh)', 'file': 'add_locales_content.txt'}],
        'remove_startup_beep': [{'id': 'nobeep_conf_personal', 'label': 'NoBeep Conf', 'dialogTitle': 'Configuração NoBeep (archPI-personal.sh)', 'file': 'remove_startup_beep_content.txt'}]
    }
}

class EditFunctionDialog(Adw.Dialog):
    def __init__(self, parent_window, title, full_file_path):
        super().__init__(transient_for=parent_window.get_root(), modal=True)
        self.full_file_path = full_file_path
        self.parent_window = parent_window
        self.set_title(title)
        self.set_default_size(500, 400)
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin_top=10, margin_bottom=10, margin_start=10, margin_end=10)
        self.set_child(content_box)
        self.text_view = Gtk.TextView(wrap_mode=Gtk.WrapMode.WORD_CHAR, vexpand=True, hexpand=True, monospace=True)
        scrolled_window = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.AUTOMATIC, vscrollbar_policy=Gtk.PolicyType.AUTOMATIC)
        scrolled_window.set_child(self.text_view)
        content_box.append(scrolled_window)
        self.add_response("cancel", "Cancelar")
        self.add_response("save", "Salvar")
        self.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response("save")
        self.connect('response', self._on_dialog_response)
        self._load_content()

    def _load_content(self):
        try:
            if not GLib.file_test(self.full_file_path, GLib.FileTest.EXISTS):
                self.parent_window._show_toast(f"Arquivo não encontrado: {self.full_file_path}")
                self.text_view.get_buffer().set_text(f"Arquivo não encontrado: {self.full_file_path}\nCrie o arquivo primeiro.", -1)
                return
            ok, contents_bytes, _ = GLib.file_get_contents(self.full_file_path)
            if ok:
                self.text_view.get_buffer().set_text(contents_bytes.decode('utf-8'), -1)
            else:
                raise Exception('Falha ao ler o conteúdo do arquivo.')
        except Exception as e:
            error_msg = f"Erro ao carregar {self.full_file_path}: {e}"
            print(error_msg)
            self.parent_window._show_toast(error_msg)
            self.text_view.get_buffer().set_text(f"Erro ao carregar arquivo: {e}", -1)

    def _save_content(self):
        buffer = self.text_view.get_buffer()
        start_iter, end_iter = buffer.get_bounds()
        text_content = buffer.get_text(start_iter, end_iter, False)
        content_bytes = text_content.encode('utf-8')
        try:
            parent_dir = GLib.path_get_dirname(self.full_file_path)
            if not GLib.file_test(parent_dir, GLib.FileTest.IS_DIR):
                GLib.mkdir_with_parents(parent_dir, 0o755)
            GLib.file_set_contents_bytes(self.full_file_path, GLib.Bytes.new(content_bytes))
            self.parent_window._show_toast(f"Configuração salva em {self.full_file_path}")
        except Exception as e:
            error_msg = f"Erro ao salvar {self.full_file_path}: {e}"
            print(error_msg)
            self.parent_window._show_toast(error_msg)

    def _on_dialog_response(self, dialog, response_id):
        if response_id == "save": self._save_content()
        self.close()

class AppWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.app_base_dir = None
        try:
            self.app_base_dir = GLib.path_get_dirname(GLib.file_get_real_path(__file__))
        except NameError:
            print("Aviso: __file__ não está definido. Usando o diretório de trabalho atual como base.")
            self.app_base_dir = GLib.get_current_dir()

        self.set_title('Configurador ArchPI (Python)')
        self.set_default_size(700, 850)

        # 2. Inicializações para execução de script
        self.script_process = None
        self.stdout_watch_id = None
        self.stderr_watch_id = None
        self.active_pipe_watches = 0 # Para contar HUPs

        self.toast_overlay = Adw.ToastOverlay()
        self.set_content(self.toast_overlay)
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin_top=10, margin_bottom=10, margin_start=10, margin_end=10)
        self.toast_overlay.set_child(self.main_box)
        top_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.main_box.append(top_box)
        script_selector_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        script_selector_box.set_halign(Gtk.Align.CENTER)
        script_label = Gtk.Label(label="Script para configurar:")
        script_selector_box.append(script_label)
        self.script_combo_box = Gtk.ComboBoxText()
        self.script_combo_box.append_text("archPI.sh")
        self.script_combo_box.append_text("archPI-personal.sh")
        self.script_combo_box.set_active(0)
        self.current_script_name = self.script_combo_box.get_active_text()
        self.script_combo_box.connect('changed', self._on_script_changed)
        script_selector_box.append(self.script_combo_box)
        top_box.append(script_selector_box)
        separator = Gtk.Separator(margin_top=5, margin_bottom=5)
        top_box.append(separator)
        self.scrolled_window = Gtk.ScrolledWindow()
        self.scrolled_window.set_hscrollbar_policy(Gtk.PolicyType.NEVER)
        self.scrolled_window.set_vscrollbar_policy(Gtk.PolicyType.AUTOMATIC)
        self.scrolled_window.set_min_content_height(300)
        self.scrolled_window.set_vexpand(True)
        self.functions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin_start=10, margin_end=10)
        self.scrolled_window.set_child(self.functions_box)
        top_box.append(self.scrolled_window)
        self.output_expander = Adw.ExpanderRow(title="Saída da Execução", expanded=False)
        top_box.append(self.output_expander)
        output_scrolled_window = Gtk.ScrolledWindow()
        output_scrolled_window.set_min_content_height(200)
        self.output_text_view = Gtk.TextView(editable=False, cursor_visible=False, wrap_mode=Gtk.WrapMode.WORD_CHAR, monospace=True)

        # Tags para output TextView
        buffer = self.output_text_view.get_buffer()
        self.stderr_tag = buffer.create_tag("stderr_tag", foreground="red")
        # self.stdout_tag = buffer.create_tag("stdout_tag", foreground="blue") # Opcional

        output_scrolled_window.set_child(self.output_text_view)
        self.output_expander.add_row(output_scrolled_window)
        bottom_buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        bottom_buttons_box.set_halign(Gtk.Align.END)
        self.save_button = Gtk.Button(label="Salvar Configurações Script")
        self.save_button.connect('clicked', self._on_save_configuration_clicked)
        bottom_buttons_box.append(self.save_button)
        self.execute_script_button = Gtk.Button(label="Executar Script Configurado") # Nome atualizado
        self.execute_script_button.add_css_class("suggested-action")
        self.execute_script_button.connect('clicked', self._on_execute_script_clicked)
        bottom_buttons_box.append(self.execute_script_button)
        top_box.append(bottom_buttons_box)
        self.parsed_functions = []
        self.script_structure = {}
        self._load_and_display_functions()

    def _show_toast(self, message):
        toast = Adw.Toast(title=message, timeout=3)
        self.toast_overlay.add_toast(toast)

    def _build_script_path(self, script_name):
        return GLib.build_filenamev([self.app_base_dir, script_name])

    def _build_data_file_path(self, relative_file_path):
        if not self.current_script_name:
            self._show_toast("Erro: Nome do script atual não definido.")
            return None
        return GLib.build_filenamev([self.app_base_dir, 'data', self.current_script_name, relative_file_path])

    def _read_script_content(self, script_name):
        script_path = self._build_script_path(script_name)
        if not GLib.file_test(script_path, GLib.FileTest.EXISTS):
            raise FileNotFoundError(f"Arquivo de script não encontrado: {script_path}")
        try:
            ok, contents_bytes, _ = GLib.file_get_contents(script_path)
            if ok: return contents_bytes.decode('utf-8')
            else: raise Exception(f"Falha ao ler o arquivo de script: {script_path}")
        except Exception as e: raise Exception(f"Exceção ao ler {script_path}: {e}")

    def _parse_script_functions(self, script_name):
        content = self._read_script_content(script_name) # Erros de leitura são propagados
        lines = content.split('\n')
        functions, in_commands_block, block_start_index, block_end_index = [], False, -1, -1
        for i, line_text in enumerate(lines):
            trimmed_line = line_text.strip()
            if trimmed_line == COMMANDS_BLOCK_DELIMITER_LINE and not in_commands_block:
                if (i + 2) < len(lines) and lines[i+1].strip() == COMMANDS_BLOCK_START_TEXT and lines[i+2].strip() == COMMANDS_BLOCK_DELIMITER_LINE:
                    in_commands_block, block_start_index = True, i + 3
                    continue
            if in_commands_block:
                if not trimmed_line or trimmed_line.startswith("finalization"):
                    if trimmed_line.startswith("finalization"): functions.append({'name': "finalization", 'active': True, 'is_finalization': True})
                    block_end_index = i; break
                is_commented = trimmed_line.startswith("#")
                function_name = trimmed_line.lstrip("#").strip()
                if function_name:
                    func_data = {'name': function_name, 'active': not is_commented}
                    if self.current_script_name in EXTERNAL_CONFIGS and function_name in EXTERNAL_CONFIGS[self.current_script_name]:
                        func_data['external_configs'] = EXTERNAL_CONFIGS[self.current_script_name][function_name]
                    functions.append(func_data)
        if block_start_index != -1 and block_end_index == -1: block_end_index = len(lines)
        self.script_structure = {'lines': lines, 'block_start_index': block_start_index, 'block_end_index': block_end_index}
        return functions

    def _clear_functions_ui(self):
        child = self.functions_box.get_first_child()
        while child: self.functions_box.remove(child); child = self.functions_box.get_first_child()

    def _populate_functions_ui(self, functions):
        self._clear_functions_ui()
        if not functions: self.functions_box.append(Gtk.Label(label="Nenhuma função configurável encontrada ou erro ao ler script.")); return
        for func_data in functions:
            if func_data.get('is_finalization', False): continue
            row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            check_button = Gtk.CheckButton(label=func_data['name'], active=func_data['active'], hexpand=True)
            check_button.set_data("function-name", func_data['name'])
            row_box.append(check_button)
            if 'external_configs' in func_data and isinstance(func_data['external_configs'], list):
                details_buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6, halign=Gtk.Align.END)
                for config_meta in func_data['external_configs']:
                    details_button = Gtk.Button(label=config_meta['label'])
                    details_button.connect('clicked', lambda w, fn=func_data['name'], cm=config_meta: self._on_edit_function_details_clicked(w, fn, cm))
                    details_buttons_box.append(details_button)
                row_box.append(details_buttons_box)
            self.functions_box.append(row_box)

    def _load_and_display_functions(self):
        if not self.current_script_name: self._clear_functions_ui(); self.functions_box.append(Gtk.Label(label="Selecione um script.")); return
        try:
            self.parsed_functions = self._parse_script_functions(self.current_script_name)
            self._populate_functions_ui(self.parsed_functions)
        except Exception as e:
            self._clear_functions_ui(); error_label = Gtk.Label(label=f"Erro ao carregar {self.current_script_name}: {e}")
            self.functions_box.append(error_label); self._show_toast(f"Falha ao carregar {self.current_script_name}: {e}")

    def _on_script_changed(self, widget):
        self.current_script_name = self.script_combo_box.get_active_text()
        self._load_and_display_functions()

    def _on_edit_function_details_clicked(self, widget, function_name, config_meta):
        dialog_title = config_meta.get('dialogTitle', f"Editar {function_name} - {config_meta.get('label', 'Detalhes')}")
        relative_file_path = config_meta.get('file')
        if not relative_file_path: self._show_toast("Erro: Arquivo de configuração não definido."); return
        full_data_path = self._build_data_file_path(relative_file_path)
        if not full_data_path: return
        dialog = EditFunctionDialog(self, dialog_title, full_data_path); dialog.present()

    def _on_save_configuration_clicked(self, widget=None, silent=False):
        script_name = self.current_script_name
        if not script_name:
            if not silent: self._show_toast("Nenhum script selecionado."); return False
        if not self.parsed_functions or not self.script_structure or self.script_structure.get('block_start_index', -1) == -1:
            if not silent: self._show_toast("Estrutura do script inválida."); return False
        checkbox_states = {}
        child = self.functions_box.get_first_child()
        while child:
            check_button_candidate = child.get_first_child()
            if isinstance(check_button_candidate, Gtk.CheckButton):
                checkbox_states[check_button_candidate.get_data("function-name")] = check_button_candidate.get_active()
            child = child.get_next_sibling()
        new_commands_block_lines = []
        for func in self.parsed_functions:
            if func.get('is_finalization', False): continue
            is_active = checkbox_states.get(func['name'], func['active'])
            new_commands_block_lines.append(f"#{func['name']}" if not is_active else func['name'])
        finalization_func = next((f for f in self.parsed_functions if f.get('is_finalization')), None)
        if finalization_func: new_commands_block_lines.append(finalization_func['name'])

        lines, start_index, end_index = self.script_structure['lines'], self.script_structure['block_start_index'], self.script_structure['block_end_index']
        new_script_content = "\n".join(lines[:start_index] + new_commands_block_lines + lines[end_index:])
        if not new_script_content.endswith("\n"): new_script_content += "\n"

        script_path = self._build_script_path(script_name)
        try:
            GLib.file_set_contents_bytes(script_path, GLib.Bytes.new(new_script_content.encode('utf-8')))
            if not silent: self._show_toast(f"Configurações salvas em {script_name}"); self._load_and_display_functions()
            return True
        except Exception as e:
            if not silent: self._show_toast(f"Erro ao salvar {script_name}: {e}"); print(f"Erro ao salvar: {e}")
            return False

    # 4. _append_to_output_view
    def _append_to_output_view(self, text, is_stderr=False):
        buffer = self.output_text_view.get_buffer()
        iter_end = buffer.get_end_iter()
        if is_stderr:
            buffer.insert_with_tags_by_name(iter_end, text, "stderr_tag")
        else:
            buffer.insert(iter_end, text)
        # Auto-scroll
        GLib.idle_add(lambda: self.output_text_view.get_parent().get_vadjustment().set_value(
            self.output_text_view.get_parent().get_vadjustment().get_upper() -
            self.output_text_view.get_parent().get_vadjustment().get_page_size()))


    # 5. _on_pipe_output
    def _on_pipe_output(self, source_fd, condition, stream, is_stderr):
        # Note: 'source_fd' e 'stream' são o mesmo objeto de pipe aqui,
        # pois passamos o stream como user_data. Usaremos 'stream'.
        if condition & GLib.IOCondition.HUP:
            self.active_pipe_watches -= 1
            if self.active_pipe_watches == 0:
                self._process_finished()
            return GLib.SOURCE_REMOVE

        line = stream.readline() # text=True e universal_newlines=True no Popen fazem isso funcionar
        if line:
            self._append_to_output_view(line, is_stderr)

        return GLib.SOURCE_CONTINUE

    # 6. _process_finished
    def _process_finished(self):
        self.execute_script_button.set_sensitive(True)
        if self.script_process:
            # Tentar obter o código de retorno. poll() é não bloqueante.
            # Se o processo já terminou, poll() retorna o código de saída.
            # Se ainda estiver rodando (improvável se ambos os HUPs foram recebidos), retorna None.
            return_code = self.script_process.poll()

            if return_code is None: # Se ainda não terminou, espere um pouco (não ideal, mas simples)
                 try:
                     self.script_process.wait(timeout=0.2)
                     return_code = self.script_process.returncode
                 except subprocess.TimeoutExpired:
                     print("Processo não terminou após timeout em _process_finished.")
                     self._show_toast(f"Script '{self.current_script_name}' finalizou, mas o código de saída não pôde ser determinado imediatamente.")
                     return_code = "Desconhecido (timeout)"


            if return_code is not None:
                self._show_toast(f"Execução finalizada com código: {return_code}")
            else:
                # Se ainda não temos returncode (raro aqui se os HUPs vieram),
                self._show_toast(f"Execução do script '{self.current_script_name}' concluída.")

        # Limpar referências e IDs de watch
        if self.stdout_watch_id:
            GLib.source_remove(self.stdout_watch_id)
            self.stdout_watch_id = None
        if self.stderr_watch_id:
            GLib.source_remove(self.stderr_watch_id)
            self.stderr_watch_id = None
        self.script_process = None
        self.active_pipe_watches = 0


    # 3. Modificar _on_execute_script_clicked
    def _on_execute_script_clicked(self, widget):
        if self.script_process:
            self._show_toast("Um script já está em execução.")
            return

        saved_successfully = self._on_save_configuration_clicked(silent=True)
        if not saved_successfully:
            self._show_toast("Falha ao salvar configurações. Execução cancelada.")
            return
        # self._show_toast("Configurações salvas. Iniciando script...") # Opcional, pode ser verboso

        self.output_text_view.get_buffer().set_text("") # Limpar saída anterior
        self.output_expander.set_expanded(True)
        self.execute_script_button.set_sensitive(False)

        script_path = self._build_script_path(self.current_script_name)
        if not GLib.file_test(script_path, GLib.FileTest.EXISTS):
            self._append_to_output_view(f"ERRO: Script não encontrado em {script_path}\n", is_stderr=True)
            self.execute_script_button.set_sensitive(True)
            return

        try:
            os.chmod(script_path, 0o755)
        except Exception as e:
            self._append_to_output_view(f"ERRO: Falha ao tornar o script executável: {e}\n", is_stderr=True)
            self.execute_script_button.set_sensitive(True)
            return

        command = ['pkexec', script_path]
        try:
            self.script_process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1, # Garante que seja line-buffered
                universal_newlines=True, # Converte newlines para '\n'
                cwd=self.app_base_dir
            )
        except Exception as e:
            self._append_to_output_view(f"Erro ao iniciar o script: {e}\n", is_stderr=True)
            self.execute_script_button.set_sensitive(True)
            self.script_process = None
            return

        self.active_pipe_watches = 0
        if self.script_process.stdout:
            self.stdout_watch_id = GLib.io_add_watch(
                self.script_process.stdout.fileno(),
                GLib.IOCondition.IN | GLib.IOCondition.HUP,
                self._on_pipe_output,
                self.script_process.stdout, # user_data: o stream
                False # is_stderr
            )
            self.active_pipe_watches +=1

        if self.script_process.stderr:
            self.stderr_watch_id = GLib.io_add_watch(
                self.script_process.stderr.fileno(),
                GLib.IOCondition.IN | GLib.IOCondition.HUP,
                self._on_pipe_output,
                self.script_process.stderr, # user_data: o stream
                True # is_stderr
            )
            self.active_pipe_watches +=1

        if self.active_pipe_watches == 0: # Caso nenhum pipe tenha sido aberto
            self._process_finished()


class ArchPIConfiguratorApp(Adw.Application):
    def __init__(self, **kwargs):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.FLAGS_NONE, **kwargs)
        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        self.win = AppWindow(application=app)
        self.win.present()

def main():
    app = ArchPIConfiguratorApp()
    return app.run(sys.argv)

if __name__ == '__main__':
    sys.exit(main())
