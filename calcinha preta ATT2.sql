
CREATE TABLE Pacientes (
    id_paciente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    especie VARCHAR(50),
    idade INT DEFAULT 0
);

CREATE TABLE Veterinarios (
    id_veterinario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50)
);

CREATE TABLE Consultas (
    id_consulta INT PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT,
    id_veterinario INT,
    data_consulta DATE,
    custo DECIMAL(10, 2),
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario)
);

CREATE TABLE Donos (
    id_dono INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(15),
    endereco VARCHAR(255)
);

CREATE TABLE Medicamentos (
    id_medicamento INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    dosagem VARCHAR(50)
);

CREATE TABLE Prescricoes (
    id_prescricao INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    id_medicamento INT,
    dose VARCHAR(50),
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta),
    FOREIGN KEY (id_medicamento) REFERENCES Medicamentos(id_medicamento)
);

CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2)
);

CREATE TABLE Log_Donos (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_dono INT,
    novo_nome VARCHAR(100)
);

DELIMITER //
CREATE TRIGGER verificar_telefone_dono
BEFORE INSERT ON Donos
FOR EACH ROW
BEGIN
    IF NEW.telefone NOT REGEXP '^[0-9]{10,15}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Telefone deve ter entre 10 e 15 dígitos.';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER definir_idade_default
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade IS NULL THEN
        SET NEW.idade = 0; -- Define idade como 0 se não for fornecida
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER evitar_medicamento_duplicado
BEFORE INSERT ON Medicamentos
FOR EACH ROW
BEGIN
    DECLARE medicamento_existente INT;
    SELECT COUNT(*) INTO medicamento_existente FROM Medicamentos WHERE nome = NEW.nome;
    IF medicamento_existente > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento já cadastrado.';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER registrar_atualizacao_dono
AFTER UPDATE ON Donos
FOR EACH ROW
BEGIN
    INSERT INTO Log_Donos (id_dono, novo_nome) VALUES (OLD.id_dono, NEW.nome);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER limitar_prescricao_por_consulta
BEFORE INSERT ON Prescricoes
FOR EACH ROW
BEGIN
    DECLARE prescricao_existente INT;
    SELECT COUNT(*) INTO prescricao_existente FROM Prescricoes WHERE id_consulta = NEW.id_consulta AND id_medicamento = NEW.id_medicamento;
    IF prescricao_existente > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicamento já prescrito para esta consulta.';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE cadastrar_dono(
    IN novo_nome VARCHAR(100),
    IN novo_telefone VARCHAR(15),
    IN novo_endereco VARCHAR(255)
)
BEGIN
    INSERT INTO Donos (nome, telefone, endereco) VALUES (novo_nome, novo_telefone, novo_endereco);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE cadastrar_medicamento(
    IN nome_medicamento VARCHAR(100),
    IN dosagem_medicamento VARCHAR(50)
)
BEGIN
    INSERT INTO Medicamentos (nome, dosagem) VALUES (nome_medicamento, dosagem_medicamento);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE prescrever_medicamento(
    IN id_consulta INT,
    IN id_medicamento INT,
    IN dose VARCHAR(50)
)
BEGIN
    INSERT INTO Prescricoes (id_consulta, id_medicamento, dose) VALUES (id_consulta, id_medicamento, dose);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE listar_medicamentos_por_consulta(
    IN id_consulta INT
)
BEGIN
    SELECT m.nome, p.dose
    FROM Prescricoes p
    JOIN Medicamentos m ON p.id_medicamento = m.id_medicamento
    WHERE p.id_consulta = id_consulta;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE atualizar_telefone_dono(
    IN id_dono INT,
    IN novo_telefone VARCHAR(15)
)
BEGIN
    UPDATE Donos SET telefone = novo_telefone WHERE id_dono = id_dono;
END //
DELIMITER ;

-- Exemplos de uso das procedures
CALL cadastrar_dono('Maria Silva', '1234567890', 'Rua das Flores, 123');
CALL cadastrar_medicamento('Antibiótico', '500mg');
CALL prescrever_medicamento(1, 1, '1 vez ao dia');
CALL listar_medicamentos_por_consulta(1);
CALL atualizar_telefone_dono(1, '0987654321');
