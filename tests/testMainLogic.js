// tests/testMainLogic.js
import { getTestUnits } from 'resource:///org/gnome/gjs/modules/testing/unit.js';
import GLib from 'gi://GLib';
import System from 'system'; // Para assert

// --- Lógica Replicada/Adaptada de main.js ---

// Delimitadores (copiados de main.js)
const COMMANDS_BLOCK_DELIMITER_LINE = "#------------------------------------------------------------------------ #";
const COMMANDS_BLOCK_START_TEXT = "# Commands (uncomment the ones you want to use)";

// Estrutura Mock/Exemplo de EXTERNAL_CONFIGS (copiada e simplificada de main.js)
const MOCK_EXTERNAL_CONFIGS = {
    'archPI.sh': {
        'install_yay': [
            { id: 'pacman_deps', label: 'Pacman', file: 'install_yay_pacman_dependencies.txt' }
        ],
        'add_locales': [
            { id: 'locales_cfg', label: 'Locales', file: 'add_locales_content.txt' }
        ]
    },
    'anotherScript.sh': {
        'some_function': [
            { id: 'cfg1', label: 'Config1', file: 'some_function_cfg1.txt' }
        ]
    }
};

// Lógica de parseamento de script (adaptada de AppWindow._parseScriptFunctions)
function parseScriptFunctionsForTest(scriptContent, scriptName, externalConfigsForScript) {
    const lines = scriptContent.split('\n');
    const functions = [];
    let inCommandsBlock = false;
    // Não precisamos dos índices de bloco para este teste de lógica pura de parseamento
    // let commandsBlockStartIndex = -1;
    // let commandsBlockEndIndex = -1;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line === COMMANDS_BLOCK_DELIMITER_LINE && !inCommandsBlock) {
            const nextLineIndex = i + 1;
            if (nextLineIndex < lines.length && lines[nextLineIndex].trim() === COMMANDS_BLOCK_START_TEXT) {
                const afterNextLineIndex = nextLineIndex + 1;
                if (afterNextLineIndex < lines.length && lines[afterNextLineIndex].trim() === COMMANDS_BLOCK_DELIMITER_LINE) {
                    inCommandsBlock = true;
                    // commandsBlockStartIndex = afterNextLineIndex + 1;
                    i = afterNextLineIndex; // Pular as linhas de delimitador
                    continue;
                }
            }
        }

        if (inCommandsBlock) {
            if (line === "" || line.startsWith("finalization")) {
                if (line.startsWith("finalization")) {
                    functions.push({ name: "finalization", active: true, isFinalization: true });
                }
                // commandsBlockEndIndex = i;
                break;
            }

            const isCommented = line.startsWith("#");
            const functionName = isCommented ? line.substring(1).trim() : line;

            if (functionName) {
                const funcData = { name: functionName, active: !isCommented };
                if (externalConfigsForScript && externalConfigsForScript[functionName]) {
                    funcData.externalConfigs = externalConfigsForScript[functionName];
                }
                functions.push(funcData);
            }
        }
    }
    return functions;
}

// Lógica de helper de caminho (adaptada de AppWindow._buildScriptPath)
function buildScriptPathForTest(appBaseDir, scriptFileName) {
    return GLib.build_filenamev([appBaseDir, scriptFileName]);
}

// Lógica de helper de caminho (adaptada de AppWindow._buildDataFilePath)
function buildDataFilePathForTest(appBaseDir, currentScript, relativePath) {
    return GLib.build_filenamev([appBaseDir, 'data', currentScript, relativePath]);
}


// --- Testes Unitários ---

getTestUnits().addTest('Test Path Helpers: buildScriptPathForTest', function() {
    const mockAppBaseDir = '/usr/share/archpi-configurator';
    const scriptName = 'archPI.sh';
    const expectedPath = '/usr/share/archpi-configurator/archPI.sh';
    const resultPath = buildScriptPathForTest(mockAppBaseDir, scriptName);
    System.assert(resultPath === expectedPath, `Expected script path ${expectedPath}, got ${resultPath}`);
});

getTestUnits().addTest('Test Path Helpers: buildDataFilePathForTest', function() {
    const mockAppBaseDir = '/opt/archpi-configurator';
    const scriptName = 'archPI-personal.sh';
    const relativePath = 'some_config.txt';
    const expectedPath = '/opt/archpi-configurator/data/archPI-personal.sh/some_config.txt';
    const resultPath = buildDataFilePathForTest(mockAppBaseDir, scriptName, relativePath);
    System.assert(resultPath === expectedPath, `Expected data file path ${expectedPath}, got ${resultPath}`);
});

getTestUnits().addTest('Test _parseScriptFunctions: Basic Valid Script', function() {
    const mockScriptContent = `
#!/bin/bash
# ... other stuff ...
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
install_yay
#add_locales
another_function
finalization
`;
    const functions = parseScriptFunctionsForTest(mockScriptContent, 'archPI.sh', MOCK_EXTERNAL_CONFIGS['archPI.sh']);

    System.assert(functions.length === 4, `Expected 4 functions, got ${functions.length}`);

    const fnYay = functions.find(f => f.name === 'install_yay');
    System.assert(fnYay !== undefined, "Function 'install_yay' not found");
    System.assert(fnYay.active === true, "Function 'install_yay' should be active");
    System.assert(Array.isArray(fnYay.externalConfigs), "'install_yay' should have externalConfigs array");
    System.assert(fnYay.externalConfigs[0].file === 'install_yay_pacman_dependencies.txt', "Incorrect externalConfig for 'install_yay'");

    const fnLocales = functions.find(f => f.name === 'add_locales');
    System.assert(fnLocales !== undefined, "Function 'add_locales' not found");
    System.assert(fnLocales.active === false, "Function 'add_locales' should be inactive (commented)");
    System.assert(Array.isArray(fnLocales.externalConfigs), "'add_locales' should have externalConfigs array");

    const fnAnother = functions.find(f => f.name === 'another_function');
    System.assert(fnAnother !== undefined, "Function 'another_function' not found");
    System.assert(fnAnother.active === true, "Function 'another_function' should be active");
    System.assert(fnAnother.externalConfigs === undefined, "'another_function' should not have externalConfigs");

    const fnFinalization = functions.find(f => f.name === 'finalization');
    System.assert(fnFinalization !== undefined, "Function 'finalization' not found");
    System.assert(fnFinalization.active === true, "Function 'finalization' should be active");
    System.assert(fnFinalization.isFinalization === true, "Function 'finalization' should have isFinalization flag");
});

getTestUnits().addTest('Test _parseScriptFunctions: Empty Commands Block', function() {
    const mockScriptContent = `
#!/bin/bash
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #

finalization
`;
    const functions = parseScriptFunctionsForTest(mockScriptContent, 'archPI.sh', MOCK_EXTERNAL_CONFIGS['archPI.sh']);
    System.assert(functions.length === 1, `Expected 1 function (finalization), got ${functions.length}`);
    System.assert(functions[0].name === 'finalization', "Expected 'finalization'");
});

getTestUnits().addTest('Test _parseScriptFunctions: No Commands Block Delimiter', function() {
    const mockScriptContent = `
#!/bin/bash
install_yay
#another_function
`;
    const functions = parseScriptFunctionsForTest(mockScriptContent, 'archPI.sh', MOCK_EXTERNAL_CONFIGS['archPI.sh']);
    System.assert(functions.length === 0, `Expected 0 functions, got ${functions.length}`);
});

getTestUnits().addTest('Test _parseScriptFunctions: Functions with Hyphens and Special Chars', function() {
    const mockScriptContent = `
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
install-stuff
#config_with_underscore
test_func-123
finalization
`;
    const functions = parseScriptFunctionsForTest(mockScriptContent, 'anotherScript.sh', MOCK_EXTERNAL_CONFIGS['anotherScript.sh']);
    System.assert(functions.length === 4, `Expected 4 functions, got ${functions.length}`);
    System.assert(functions.find(f => f.name === 'install-stuff').active === true, "'install-stuff' should be active");
    System.assert(functions.find(f => f.name === 'config_with_underscore').active === false, "'config_with_underscore' should be inactive");
    System.assert(functions.find(f => f.name === 'test_func-123').active === true, "'test_func-123' should be active");
});


getTestUnits().addTest('Test _parseScriptFunctions: No Matching External Configs', function() {
    const mockScriptContent = `
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
unique_function_no_config
finalization
`;
    // Pass externalConfigs for a different script or an empty one for this script
    const functions = parseScriptFunctionsForTest(mockScriptContent, 'archPI.sh', {});
    System.assert(functions.length === 2, `Expected 2 functions, got ${functions.length}`);
    const fnUnique = functions.find(f => f.name === 'unique_function_no_config');
    System.assert(fnUnique !== undefined, "Function 'unique_function_no_config' not found");
    System.assert(fnUnique.active === true, "Function 'unique_function_no_config' should be active");
    System.assert(fnUnique.externalConfigs === undefined, "'unique_function_no_config' should not have externalConfigs");
});

// Para executar: gjs tests/testMainLogic.js
// (Ou System.exit(getTestUnits().run()); para sair com código de status apropriado)
// Para esta subtarefa, apenas criar o arquivo é suficiente.
// Adicionando System.exit para que possa ser executado de forma mais completa se desejado.
if (System.programArgs.includes('--run')) {
    System.exit(getTestUnits().run());
}
