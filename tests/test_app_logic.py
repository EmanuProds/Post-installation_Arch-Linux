import unittest
import os # Necessário para os.linesep se for usar na lógica de reconstrução
from gi.repository import GLib # Para GLib.build_filenamev

# --- Lógica Replicada/Adaptada de main_python.py ---
# (Coloque as constantes e a classe MockAppWindow com os métodos
# _parse_script_functions, _build_script_path, _build_data_file_path
# aqui, como definido na descrição da Etapa 9 do plano).

COMMANDS_BLOCK_DELIMITER_LINE = "#------------------------------------------------------------------------ #"
COMMANDS_BLOCK_START_TEXT = "# Commands (uncomment the ones you want to use)"

class MockAppWindow:
    def __init__(self, app_base_dir, current_script_name):
        self.app_base_dir = app_base_dir
        self.current_script_name = current_script_name
        self.parsed_functions = []
        self.script_structure = {}
        # Estas constantes são usadas por _parse_script_functions
        self.COMMANDS_BLOCK_DELIMITER_LINE = COMMANDS_BLOCK_DELIMITER_LINE
        self.COMMANDS_BLOCK_START_TEXT = COMMANDS_BLOCK_START_TEXT

    def _build_script_path(self, script_name_to_build):
        # Assegura que app_base_dir e script_name_to_build não sejam None
        if self.app_base_dir is None or script_name_to_build is None:
            raise ValueError("app_base_dir e script_name_to_build não podem ser None")
        return GLib.build_filenamev([self.app_base_dir, script_name_to_build])

    def _build_data_file_path(self, relative_file_path):
        # Assegura que os componentes do caminho não sejam None
        if self.app_base_dir is None or self.current_script_name is None or relative_file_path is None:
            raise ValueError("Componentes do caminho não podem ser None para _build_data_file_path")
        return GLib.build_filenamev([self.app_base_dir, 'data', self.current_script_name, relative_file_path])

    def _parse_script_functions(self, script_content_str):
        if script_content_str is None:
            self.parsed_functions = []
            self.script_structure = {'lines': [], 'block_start_index': -1, 'block_end_index': -1}
            return []

        lines = script_content_str.splitlines() # Usar splitlines() para melhor portabilidade de newlines
        functions = []
        in_commands_block = False
        block_start_index = -1
        block_end_index = -1 # Onde o bloco termina (na linha 'finalization' ou linha em branco antes do suffix)

        # Encontrar o início do bloco de comandos
        for i, line_content in enumerate(lines):
            line_trimmed = line_content.strip()
            if line_trimmed == self.COMMANDS_BLOCK_DELIMITER_LINE and not in_commands_block:
                if i + 2 < len(lines) and \
                   lines[i+1].strip() == self.COMMANDS_BLOCK_START_TEXT and \
                   lines[i+2].strip() == self.COMMANDS_BLOCK_DELIMITER_LINE:
                    in_commands_block = True
                    block_start_index = i + 3 # O conteúdo real começa após o segundo delimitador
                    # Continuar a partir daqui para ler as funções
                    break
            # Se não achou o início do bloco, block_start_index continua -1

        if in_commands_block:
            # Ler funções dentro do bloco
            for i in range(block_start_index, len(lines)):
                line_trimmed = lines[i].strip()

                if not line_trimmed or line_trimmed.startswith("finalization"): # Fim do bloco
                    if line_trimmed.startswith("finalization"):
                        functions.append({'name': 'finalization', 'active': True, 'is_finalization': True})
                    block_end_index = i
                    break

                is_commented = line_trimmed.startswith("#")
                function_name = line_trimmed[1:].strip() if is_commented else line_trimmed

                if function_name: # Evitar adicionar entradas vazias se a linha for só '#'
                    functions.append({'name': function_name, 'active': not is_commented})
            else: # Se o loop terminar sem break (sem finalization e sem linha em branco)
                block_end_index = len(lines)
        else: # Bloco de comandos não encontrado
            block_start_index = -1 # Garante que é -1 se o bloco não foi encontrado
            block_end_index = -1

        self.script_structure = {'lines': lines, 'block_start_index': block_start_index, 'block_end_index': block_end_index}
        self.parsed_functions = functions
        return functions

# --- Casos de Teste ---
class TestAppLogic(unittest.TestCase):
    def setUp(self):
        self.base_dir = "/tmp/test_archpi_config"
        self.mock_window_archpi = MockAppWindow(self.base_dir, "archPI.sh")
        # self.mock_window_personal = MockAppWindow(self.base_dir, "archPI-personal.sh") # Descomente se for usar

    def test_build_script_path(self):
        expected_path = GLib.build_filenamev([self.base_dir, "archPI.sh"])
        self.assertEqual(self.mock_window_archpi._build_script_path("archPI.sh"), expected_path)

    def test_build_data_file_path(self):
        expected_path = GLib.build_filenamev([self.base_dir, 'data', "archPI.sh", "test.txt"])
        self.assertEqual(self.mock_window_archpi._build_data_file_path("test.txt"), expected_path)

    def test_parse_valid_script(self):
        mock_content = (
            "#!/bin/bash\n"
            "some_other_command\n"
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            f"{COMMANDS_BLOCK_START_TEXT}\n"
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            "func1\n"
            "#func2\n"
            "func3_with_underscores\n"
            "# func4-with-hyphens\n"
            "finalization\n"
            "after_block_command\n"
        )
        # Simula a leitura do script e parseamento
        parsed = self.mock_window_archpi._parse_script_functions(mock_content)

        self.assertEqual(len(parsed), 5, "Número de funções parseadas")
        self.assertEqual(parsed[0]['name'], 'func1')
        self.assertTrue(parsed[0]['active'])
        self.assertEqual(parsed[1]['name'], 'func2')
        self.assertFalse(parsed[1]['active'])
        self.assertEqual(parsed[2]['name'], 'func3_with_underscores')
        self.assertTrue(parsed[2]['active'])
        self.assertEqual(parsed[3]['name'], 'func4-with-hyphens')
        self.assertFalse(parsed[3]['active'])
        self.assertTrue(parsed[4].get('is_finalization'))

        # Verificar script_structure (índices são baseados em 0)
        # Linhas: 0, 1, 2(delim), 3(texto), 4(delim), 5(func1)... 9(finalization), 10(after)
        # block_start_index deve ser 5 (linha de func1)
        # block_end_index deve ser 9 (linha de finalization)
        self.assertEqual(self.mock_window_archpi.script_structure['block_start_index'], 5, "Índice de início do bloco")
        self.assertEqual(self.mock_window_archpi.script_structure['block_end_index'], 9, "Índice de fim do bloco")

    def test_parse_empty_commands_block(self):
        mock_content = (
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            f"{COMMANDS_BLOCK_START_TEXT}\n"
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            "finalization\n"
        )
        parsed = self.mock_window_archpi._parse_script_functions(mock_content)
        self.assertEqual(len(parsed), 1)
        self.assertTrue(parsed[0].get('is_finalization'))
        self.assertEqual(self.mock_window_archpi.script_structure['block_start_index'], 3)
        self.assertEqual(self.mock_window_archpi.script_structure['block_end_index'], 3)


    def test_parse_no_command_block_delimiter(self):
        mock_content = (
            "func1\n"
            "#func2\n"
        )
        parsed = self.mock_window_archpi._parse_script_functions(mock_content)
        self.assertEqual(len(parsed), 0)
        self.assertEqual(self.mock_window_archpi.script_structure['block_start_index'], -1) # Esperado
        self.assertEqual(self.mock_window_archpi.script_structure['block_end_index'], -1)  # Esperado

    def test_parse_block_with_only_comments_and_finalization(self):
        mock_content = (
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            f"{COMMANDS_BLOCK_START_TEXT}\n"
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            "#comment1\n"
            "#comment2\n"
            "finalization\n"
        )
        parsed = self.mock_window_archpi._parse_script_functions(mock_content)
        self.assertEqual(len(parsed), 3) # comment1, comment2, finalization
        self.assertEqual(parsed[0]['name'], 'comment1'); self.assertFalse(parsed[0]['active'])
        self.assertEqual(parsed[1]['name'], 'comment2'); self.assertFalse(parsed[1]['active'])
        self.assertTrue(parsed[2].get('is_finalization'))

    def test_parse_script_ends_after_commands_no_finalization(self):
        mock_content = (
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            f"{COMMANDS_BLOCK_START_TEXT}\n"
            f"{COMMANDS_BLOCK_DELIMITER_LINE}\n"
            "func_a\n"
            "#func_b\n"
        ) # Script termina aqui, sem linha em branco ou finalization
        parsed = self.mock_window_archpi._parse_script_functions(mock_content)
        self.assertEqual(len(parsed), 2)
        self.assertEqual(parsed[0]['name'], 'func_a'); self.assertTrue(parsed[0]['active'])
        self.assertEqual(parsed[1]['name'], 'func_b'); self.assertFalse(parsed[1]['active'])
        self.assertEqual(self.mock_window_archpi.script_structure['block_end_index'], 5) # Deve ser o final do array de linhas

if __name__ == '__main__':
    unittest.main()
