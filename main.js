// SPDX-License-Identifier: MIT
//
// Exemplo de uma aplicação GJS com Libadwaita e GTK4
// Este é o arquivo principal da aplicação.

// Importar as bibliotecas necessárias
import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

// ID da Aplicação
const APP_ID = 'org.example.ArchPIConfigurator';

// Delimitadores para o bloco de comandos nos scripts Bash
const COMMANDS_BLOCK_DELIMITER_LINE = "#------------------------------------------------------------------------ #";
const COMMANDS_BLOCK_START_TEXT = "# Commands (uncomment the ones you want to use)";

// Mapeamento de funções para suas configurações externalizadas
// Caminhos de arquivo agora são relativos ao subdiretório data/<script_name>/
const EXTERNAL_CONFIGS = {
    'archPI.sh': {
        'install_yay': [
            {
                id: 'pacman_dependencies',
                label: 'Pacman Deps',
                dialogTitle: 'Dependências Pacman do Yay (archPI.sh)',
                file: 'install_yay_pacman_dependencies.txt', // Caminho relativo
            }
        ],
        'add_locales': [
            {
                id: 'locales_list',
                label: 'Locales',
                dialogTitle: 'Locales a serem adicionados (archPI.sh)',
                file: 'add_locales_content.txt', // Caminho relativo
            }
        ],
        'install_zsh_terminal-customizations': [
            {
                id: 'pacman_zsh',
                label: 'Pacman',
                dialogTitle: 'Pacotes Pacman ZSH (archPI.sh)',
                file: 'install_zsh_terminal_customizations_pacman.txt', // Relativo
            },
            {
                id: 'yay_zsh',
                label: 'Yay',
                dialogTitle: 'Pacotes Yay ZSH (archPI.sh)',
                file: 'install_zsh_terminal_customizations_yay.txt', // Relativo
            },
            {
                id: 'cargo_zsh',
                label: 'Cargo',
                dialogTitle: 'Pacotes Cargo ZSH (archPI.sh)',
                file: 'install_zsh_terminal_customizations_cargo.txt', // Relativo
            }
        ],
        'install_themes_wallpapers_and_extensions': [
            {
                id: 'yay_themes',
                label: 'Yay',
                dialogTitle: 'Pacotes Yay Temas (archPI.sh)',
                file: 'install_themes_wallpapers_extensions_yay.txt', // Relativo
            },
            {
                id: 'pacman_themes',
                label: 'Pacman',
                dialogTitle: 'Pacotes Pacman Temas (archPI.sh)',
                file: 'install_themes_wallpapers_extensions_pacman.txt', // Relativo
            }
        ]
        // Adicionar 'remove_startup_beep' para archPI.sh se externalizado lá também
    },
    'archPI-personal.sh': {
        'install_apps': [
            {
                id: 'flatpak_apps',
                label: 'Flatpak',
                dialogTitle: 'Aplicativos Flatpak (archPI-personal.sh)',
                file: 'install_apps_flatpak.txt', // Relativo
            },
            {
                id: 'yay_apps',
                label: 'Yay',
                dialogTitle: 'Aplicativos Yay (archPI-personal.sh)',
                file: 'install_apps_yay.txt', // Relativo
            },
            {
                id: 'pacman_apps',
                label: 'Pacman',
                dialogTitle: 'Aplicativos Pacman (archPI-personal.sh)',
                file: 'install_apps_pacman.txt', // Relativo
            }
        ],
        'add_locales': [
            {
                id: 'locales_list_personal',
                label: 'Locales',
                dialogTitle: 'Locales a serem adicionados (archPI-personal.sh)',
                file: 'add_locales_content.txt', // Relativo
            }
        ],
        'remove_startup_beep': [
            {
                id: 'nobeep_conf',
                label: 'NoBeep Conf',
                dialogTitle: 'Configuração NoBeep (archPI-personal.sh)',
                file: 'remove_startup_beep_content.txt', // Relativo
            }
        ]
    }
};


class EditFunctionDialog extends Adw.Dialog {
    constructor(parentWindow, title, fullFilePath) { // Agora recebe fullFilePath
        super({
            transient_for: parentWindow.get_root(),
            modal: true,
        });
        this.fullFilePath = fullFilePath; // Armazena o caminho completo
        this.parentWindow = parentWindow;
        this.set_title(title);
        this.set_default_size(500, 400);
        const contentBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10, margin_top: 10, margin_bottom: 10, margin_start: 10, margin_end: 10 });
        this.set_child(contentBox);
        this.textView = new Gtk.TextView({ wrap_mode: Gtk.WrapMode.WORD_CHAR, vexpand: true, hexpand: true });
        const scrolledWindow = new Gtk.ScrolledWindow({ hscrollbar_policy: Gtk.PolicyType.AUTOMATIC, vscrollbar_policy: Gtk.PolicyType.AUTOMATIC, child: this.textView });
        contentBox.append(scrolledWindow);
        this.add_response("cancel", "Cancelar");
        this.add_response("save", "Salvar");
        this.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED);
        this.set_default_response("save");
        this.connect('response', (self, response_id) => {
            if (response_id === 'save') this._saveContent();
            this.close();
        });
        this._loadContent();
    }

    _loadContent() {
        // const fullPath = this._getFilePath(); // Não é mais necessário, já recebemos
        try {
            if (!GLib.file_test(this.fullFilePath, GLib.FileTest.EXISTS)) {
                this.parentWindow._showToast(`Arquivo não encontrado: ${this.fullFilePath}`);
                this.textView.get_buffer().set_text(`Arquivo não encontrado: ${this.fullFilePath}\nCrie o arquivo primeiro.`, -1);
                return;
            }
            const [ok, contents_bytes] = GLib.file_get_contents(this.fullFilePath);
            if (ok) this.textView.get_buffer().set_text(new TextDecoder('utf-8').decode(contents_bytes), -1);
            else throw new Error('Falha ao ler o conteúdo do arquivo.');
        } catch (e) {
            console.error(`Erro ao carregar ${this.fullFilePath}: ${e.message}`);
            this.parentWindow._showToast(`Erro ao carregar ${this.filePath}: ${e.message}`); // filePath não existe mais aqui, usar fullFilePath
            this.textView.get_buffer().set_text(`Erro ao carregar arquivo: ${e.message}`, -1);
        }
    }
    _saveContent() {
        // const fullPath = this._getFilePath(); // Não é mais necessário
        const buffer = this.textView.get_buffer();
        const [start, end] = buffer.get_bounds();
        const textContent = buffer.get_text(start, end, false);
        const contentBytes = new TextEncoder().encode(textContent);
        try {
            const parentDir = GLib.path_get_dirname(this.fullFilePath);
            if (!GLib.file_test(parentDir, GLib.FileTest.IS_DIR)) GLib.mkdir_with_parents(parentDir, 0o755);
            GLib.file_set_contents_bytes(this.fullFilePath, GLib.Bytes.new(contentBytes));
            this.parentWindow._showToast(`Configuração salva em ${this.fullFilePath}`);
        } catch (e) {
            console.error(`Erro ao salvar ${this.fullFilePath}: ${e.message}`);
            this.parentWindow._showToast(`Erro ao salvar ${this.fullFilePath}: ${e.message}`);
        }
    }
}

class ArchPIConfiguratorApp extends Adw.Application {
    constructor() { super({ application_id: APP_ID, flags: Gio.ApplicationFlags.FLAGS_NONE }); this.connect('activate', this._onActivate.bind(this)); }
    _onActivate() { this.window = new AppWindow(this); this.window.present(); }
}

class AppWindow extends Adw.ApplicationWindow {
    constructor(application) {
        super({ application: application });

        try {
            this.appBaseDir = GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]);
        } catch(e) {
            // Fallback para CWD se import.meta.url não estiver disponível (ex: execuções muito antigas de gjs ou ambientes específicos)
            console.warn("import.meta.url não está disponível, usando GLib.get_current_dir() como base. A aplicação pode não funcionar se instalada.")
            this.appBaseDir = GLib.get_current_dir();
        }

        this.currentScript = 'archPI.sh';
        this.scriptPid = null;
        this.stdout_pipe_src_id = null;
        this.stderr_pipe_src_id = null;
        this.child_watch_id = null;

        this.set_title('Configurador ArchPI');
        this.set_default_size(700, 850);

        this.toastOverlay = new Adw.ToastOverlay();
        this.set_content(this.toastOverlay);

        const mainOverlaySplit = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10, margin_top: 10, margin_bottom: 10, margin_start: 10, margin_end: 10 });
        this.toastOverlay.set_child(mainOverlaySplit);

        const topBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 });
        mainOverlaySplit.append(topBox);

        const scriptSelectorBox = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 10, halign: Gtk.Align.CENTER });
        topBox.append(scriptSelectorBox);
        const scriptLabel = new Gtk.Label({ label: 'Script para configurar:' });
        scriptSelectorBox.append(scriptLabel);
        this.scriptComboBox = new Gtk.ComboBoxText();
        this.scriptComboBox.append_text('archPI.sh');
        this.scriptComboBox.append_text('archPI-personal.sh');
        this.scriptComboBox.set_active(0);
        this.scriptComboBox.connect('changed', this._onScriptChanged.bind(this));
        scriptSelectorBox.append(this.scriptComboBox);

        topBox.append(new Gtk.Separator({ margin_top: 5, margin_bottom: 5 }));

        this.scrolledWindow = new Gtk.ScrolledWindow({ hscrollbar_policy: Gtk.PolicyType.NEVER, vscrollbar_policy: Gtk.PolicyType.AUTOMATIC, min_content_height: 300, expand: true });
        topBox.append(this.scrolledWindow);
        this.functionsBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, margin_top: 10, margin_bottom: 10, margin_start: 10, margin_end: 10 });
        this.scrolledWindow.set_child(this.functionsBox);

        this.outputExpander = new Adw.ExpanderRow({ title: "Saída da Execução", expanded: false });
        topBox.append(this.outputExpander);
        const outputScrolledWindow = new Gtk.ScrolledWindow({ hscrollbar_policy: Gtk.PolicyType.AUTOMATIC, vscrollbar_policy: Gtk.PolicyType.AUTOMATIC, min_content_height: 200 });
        this.outputTextView = new Gtk.TextView({ editable: false, cursor_visible: false, wrap_mode: Gtk.WrapMode.WORD_CHAR, monospace: true });
        const tagTable = this.outputTextView.get_buffer().get_tag_table();
        tagTable.add(new Gtk.TextTag({ name: 'stderr', foreground: 'red' }));
        outputScrolledWindow.set_child(this.outputTextView);
        this.outputExpander.add_row(outputScrolledWindow);

        const bottomButtonsBox = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 10, halign: Gtk.Align.END, margin_top: 10 });
        topBox.append(bottomButtonsBox);
        this.saveButton = new Gtk.Button({ label: 'Salvar Configurações Script' });
        this.saveButton.connect('clicked', this._onSaveConfigurationClicked.bind(this));
        bottomButtonsBox.append(this.saveButton);
        this.executeScriptButton = new Gtk.Button({ label: 'Executar Script Configurado', css_classes: ['suggested-action'] });
        this.executeScriptButton.connect('clicked', this._onExecuteScriptClicked.bind(this));
        bottomButtonsBox.append(this.executeScriptButton);

        this._loadFunctionsForCurrentScript();
    }

    _showToast(message) { const toast = new Adw.Toast({ title: message, timeout: 3 }); this.toastOverlay.add_toast(toast); }
    _onScriptChanged() { this.currentScript = this.scriptComboBox.get_active_text(); this._loadFunctionsForCurrentScript(); }
    _clearOutputView() { this.outputTextView.get_buffer().set_text("", -1); }
    _appendToOutputView(text, isStdErr = false) { /* ... (mantido como antes) ... */
        const buffer = this.outputTextView.get_buffer(); const iter = buffer.get_end_iter();
        if (isStdErr) buffer.insert_with_tags_by_name(iter, text, 'stderr');
        else buffer.insert(iter, text, -1);
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            const adj = this.outputTextView.get_parent().get_vadjustment();
            adj.set_value(adj.get_upper() - adj.get_page_size()); return GLib.SOURCE_REMOVE;
        });
    }
    _onScriptOutput(channel, condition, isStdErr) { /* ... (mantido como antes) ... */
        if (condition & GLib.IOCondition.HUP) { channel.close(); return GLib.SOURCE_REMOVE; }
        try {
            const [line, length] = channel.read_line_string(null);
            if (length > 0 && line !== null) this._appendToOutputView(line, isStdErr);
        } catch (e) { console.error(`Erro ao ler do pipe: ${e.message}`); }
        return GLib.SOURCE_CONTINUE;
    }
    _onScriptExited(pid, exitCode) { /* ... (mantido como antes) ... */
        this.executeScriptButton.set_sensitive(true); this._showToast(`Script '${this.currentScript}' finalizado com código: ${exitCode}.`); this.scriptPid = null;
        if (this.stdout_pipe_src_id) GLib.source_remove(this.stdout_pipe_src_id); this.stdout_pipe_src_id = null;
        if (this.stderr_pipe_src_id) GLib.source_remove(this.stderr_pipe_src_id); this.stderr_pipe_src_id = null;
        if(this.child_watch_id) GLib.source_remove(this.child_watch_id); this.child_watch_id = null;
    }

    // Helper para construir caminhos para arquivos de dados
    _buildDataFilePath(relativePath) {
        return GLib.build_filenamev([this.appBaseDir, 'data', this.currentScript, relativePath]);
    }

    // Helper para construir caminhos para os scripts principais
    _buildScriptPath(scriptFileName) {
        return GLib.build_filenamev([this.appBaseDir, scriptFileName]);
    }

    async _onExecuteScriptClicked() {
        if (this.scriptPid) { this._showToast("Um script já está em execução."); return; }
        const successSave = await this._onSaveConfigurationClicked(true);
        if (!successSave) { this._showToast("Falha ao salvar configurações. Execução cancelada."); return; }
        if (successSave) this._showToast("Configurações salvas. Iniciando script...");

        this._clearOutputView(); this.outputExpander.set_expanded(true); this.executeScriptButton.set_sensitive(false);

        const scriptPath = this._buildScriptPath(this.currentScript); // Usar helper
        if (!GLib.file_test(scriptPath, GLib.FileTest.EXISTS)) {
            this._appendToOutputView(`ERRO: Script não encontrado em ${scriptPath}\n`, true);
            this.executeScriptButton.set_sensitive(true); return;
        }
        try {
            const chmodProc = Gio.Subprocess.new(['chmod', '+x', scriptPath], Gio.SubprocessFlags.NONE);
            chmodProc.wait_check(null);
        } catch (e) {
             this._appendToOutputView(`ERRO: Falha ao tornar o script executável: ${e.message}\n`, true);
             this.executeScriptButton.set_sensitive(true); return;
        }
        const argv = ['pkexec', scriptPath];
        const workDir = this.appBaseDir; // Usar appBaseDir como workDir
        try {
            const [ok, pid, stdin_fd, stdout_fd, stderr_fd] = GLib.spawn_async_with_pipes(workDir, argv, null, GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP, null);
            if (!ok) throw new Error("Falha ao iniciar o processo do script.");
            this.scriptPid = pid;
            if (stdin_fd !== -1) GLib.close(stdin_fd);
            if (stdout_fd !== -1) {
                const stdoutChannel = GLib.IOChannel.unix_new(stdout_fd);
                this.stdout_pipe_src_id = stdoutChannel.add_watch(GLib.IOCondition.IN | GLib.IOCondition.HUP, (ch, cond) => this._onScriptOutput(ch, cond, false), null);
            }
            if (stderr_fd !== -1) {
                const stderrChannel = GLib.IOChannel.unix_new(stderr_fd);
                this.stderr_pipe_src_id = stderrChannel.add_watch(GLib.IOCondition.IN | GLib.IOCondition.HUP, (ch, cond) => this._onScriptOutput(ch, cond, true), null);
            }
            this.child_watch_id = GLib.child_watch_add(GLib.PRIORITY_DEFAULT, this.scriptPid, (p, status) => {
                this._onScriptExited(p, status);
                if(this.child_watch_id) GLib.source_remove(this.child_watch_id); this.child_watch_id = null;
            });
        } catch (e) {
            this._appendToOutputView(`ERRO ao executar o script: ${e.message}\n`, true);
            this.executeScriptButton.set_sensitive(true); this.scriptPid = null;
        }
    }

    _loadFunctionsForCurrentScript() {
        if (!this.currentScript) { this._clearFunctionsUI(); return; }
        try {
            this.parsedFunctions = this._parseScriptFunctions(this.currentScript);
            this._populateFunctionsUI(this.parsedFunctions, this.currentScript);
        } catch (e) {
            console.error(`Erro ao carregar ou parsear o script ${this.currentScript}: ${e}`);
            this._clearFunctionsUI(); this.parsedFunctions = [];
            const errorLabel = new Gtk.Label({ label: `Erro ao carregar ${this.currentScript}. Verifique o console.`});
            this.functionsBox.append(errorLabel); this._showToast(`Falha ao carregar ${this.currentScript}`);
        }
    }

    _readFileContent(scriptFileName) { // Renomeado para clareza
        const filePath = this._buildScriptPath(scriptFileName); // Usar helper
        if (!GLib.file_test(filePath, GLib.FileTest.EXISTS)) throw new Error(`Arquivo de script não encontrado: ${filePath}`);
        const [ok, contents_bytes] = GLib.file_get_contents(filePath);
        if (ok) return new TextDecoder('utf-8').decode(contents_bytes);
        else throw new Error(`Falha ao ler o arquivo de script: ${filePath}`);
    }

    _parseScriptFunctions(scriptName) {
        const content = this._readFileContent(scriptName); const lines = content.split('\n'); const functions = [];
        let inCommandsBlock = false; let commandsBlockStartIndex = -1; let commandsBlockEndIndex = -1;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line === COMMANDS_BLOCK_DELIMITER_LINE && !inCommandsBlock) {
                const nextLineIndex = i + 1;
                if (nextLineIndex < lines.length && lines[nextLineIndex].trim() === COMMANDS_BLOCK_START_TEXT) {
                    const afterNextLineIndex = nextLineIndex + 1;
                    if (afterNextLineIndex < lines.length && lines[afterNextLineIndex].trim() === COMMANDS_BLOCK_DELIMITER_LINE) {
                        inCommandsBlock = true; commandsBlockStartIndex = afterNextLineIndex + 1; i = afterNextLineIndex; continue;
                    }
                }
            }
            if (inCommandsBlock) {
                if (line === "" || line.startsWith("finalization")) {
                    if (line.startsWith("finalization")) functions.push({ name: "finalization", active: true, isFinalization: true });
                    commandsBlockEndIndex = i; break;
                }
                const isCommented = line.startsWith("#"); const functionName = isCommented ? line.substring(1).trim() : line;
                if (functionName) {
                    const funcData = { name: functionName, active: !isCommented };
                    // Usar scriptName (que é this.currentScript) para pegar as configs corretas
                    if (EXTERNAL_CONFIGS[scriptName] && EXTERNAL_CONFIGS[scriptName][functionName]) {
                        funcData.externalConfigs = EXTERNAL_CONFIGS[scriptName][functionName];
                    } functions.push(funcData);
                }
            }
        } this.scriptStructure = { lines, commandsBlockStartIndex, commandsBlockEndIndex }; return functions;
    }
    _clearFunctionsUI() { /* ... (mantido como antes) ... */
        let child = this.functionsBox.get_first_child();
        while (child) { this.functionsBox.remove(child); child = this.functionsBox.get_first_child(); }
    }
    _populateFunctionsUI(functions, scriptName) {
        this._clearFunctionsUI();
        if (!functions || functions.length === 0) {
            const noFunctionsLabel = new Gtk.Label({ label: 'Nenhuma função configurável encontrada.' });
            this.functionsBox.append(noFunctionsLabel); return;
        }
        for (const func of functions) {
            if (func.isFinalization) continue;
            const mainRowBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 2 });
            const topRowBox = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 6 });
            const checkButton = new Gtk.CheckButton({ label: func.name, active: func.active, hexpand: true });
            checkButton.set_data("function-name", func.name); topRowBox.append(checkButton); mainRowBox.append(topRowBox);
            if (func.externalConfigs && Array.isArray(func.externalConfigs)) {
                const detailsButtonsBox = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 6, halign: Gtk.Align.END, margin_start: 30 });
                for (const configMeta of func.externalConfigs) {
                    const detailsButton = new Gtk.Button({ label: configMeta.label });
                    // Passar o caminho relativo do configMeta.file para _onEditFunctionDetailsClicked
                    detailsButton.connect('clicked', () => this._onEditFunctionDetailsClicked(func.name, configMeta.file, configMeta.dialogTitle));
                    detailsButtonsBox.append(detailsButton);
                } topRowBox.append(detailsButtonsBox);
            } this.functionsBox.append(mainRowBox);
        }
    }

    _onEditFunctionDetailsClicked(functionName, relativeFilePath, dialogTitleOverride) {
        const dialogTitle = dialogTitleOverride || `Editar ${functionName}`;
        // Construir o caminho completo para o arquivo de dados aqui
        const fullDataPath = this._buildDataFilePath(relativeFilePath);
        const dialog = new EditFunctionDialog(this, dialogTitle, fullDataPath);
        dialog.present();
    }

    async _onSaveConfigurationClicked(silent = false) {
        const scriptName = this.currentScript;
        if (!scriptName) {
            if(!silent) this._showToast("Nenhum script selecionado.");
            return false;
        }
        if (!this.parsedFunctions || !this.scriptStructure) {
            if(!silent) this._showToast("Estrutura do script não carregada. Tente recarregar.");
            return false;
        }
        const { lines, commandsBlockStartIndex, commandsBlockEndIndex } = this.scriptStructure;
        if (commandsBlockStartIndex === -1 || commandsBlockEndIndex === -1) {
            if(!silent) this._showToast("Bloco de comandos não encontrado no script original.");
            return false;
        }
        const newCommandsBlockLines = []; const checkboxStates = new Map();
        let currentChild = this.functionsBox.get_first_child();
        while (currentChild) {
            const topRowBox = currentChild.get_first_child();
            if (topRowBox) {
                const checkButton = topRowBox.get_first_child();
                if (checkButton && checkButton instanceof Gtk.CheckButton) {
                    const funcName = checkButton.get_data("function-name");
                    checkboxStates.set(funcName, checkButton.get_active());
                }
            } currentChild = currentChild.get_next_sibling();
        }
        for (const func of this.parsedFunctions) {
            if (func.isFinalization) continue;
            const isActive = checkboxStates.get(func.name);
            if (isActive === undefined) newCommandsBlockLines.push(func.active ? func.name : `#${func.name}`);
            else newCommandsBlockLines.push(isActive ? func.name : `#${func.name}`);
        }
        const finalizationFunc = this.parsedFunctions.find(f => f.isFinalization);
        if (finalizationFunc) newCommandsBlockLines.push(finalizationFunc.name);
        const newScriptContent = lines.slice(0, commandsBlockStartIndex).join('\n') + '\n' + newCommandsBlockLines.join('\n') + '\n' + lines.slice(commandsBlockEndIndex).join('\n');

        const filePath = this._buildScriptPath(scriptName); // Usar helper
        try {
            const newContentBytes = new TextEncoder().encode(newScriptContent);
            GLib.file_set_contents_bytes(filePath, GLib.Bytes.new(newContentBytes));
            if(!silent) this._showToast(`Configurações do script salvas em ${scriptName}`);
            if(!silent) this._loadFunctionsForCurrentScript();
            return true;
        } catch (e) {
            console.error(`Erro ao salvar o script ${scriptName}: ${e}`);
            if(!silent) this._showToast(`Erro ao salvar ${scriptName}: ${e.message}`);
            return false;
        }
    }
}

const app = new ArchPIConfiguratorApp();
app.run(null);
