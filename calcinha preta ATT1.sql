Create database Calcinhapreta2;

use Calcinhapreta2;

CREATE TABLE Pacientes (
    id_paciente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    especie VARCHAR(50),
    idade INT CHECK (idade > 0) -- Garantindo que a idade seja positiva
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

CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_anterior DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2)
);

DELIMITER //
CREATE PROCEDURE agendar_consulta(
    IN paciente_id INT,
    IN veterinario_id INT,
    IN data_consulta DATE,
    IN custo DECIMAL(10, 2)
)
BEGIN
    INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo)
    VALUES (paciente_id, veterinario_id, data_consulta, custo);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE atualizar_paciente(
    IN paciente_id INT,
    IN novo_nome VARCHAR(100),
    IN nova_especie VARCHAR(50),
    IN nova_idade INT
)
BEGIN
    UPDATE Pacientes
    SET nome = novo_nome, especie = nova_especie, idade = nova_idade
    WHERE id_paciente = paciente_id;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE remover_consulta(
    IN consulta_id INT
)
BEGIN
    DELETE FROM Consultas
    WHERE id_consulta = consulta_id;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION calcular_total_gasto_paciente(
    IN paciente_id INT
) RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total_gasto DECIMAL(10, 2);
    SELECT COALESCE(SUM(custo), 0) INTO total_gasto
    FROM Consultas
    WHERE id_paciente = paciente_id;
    
    RETURN total_gasto;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER validar_idade_paciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade IS NULL OR NEW.idade <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idade deve ser um número positivo.';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER log_custo_consulta
AFTER UPDATE ON Consultas
FOR EACH ROW
BEGIN
    IF OLD.custo <> NEW.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_anterior, custo_novo)
        VALUES (OLD.id_consulta, OLD.custo, NEW.custo);
    END IF;
END //
DELIMITER ;
