EXECUTE BLOCK AS
BEGIN
	RDB$SET_CONTEXT('USER_SESSION', 'R$C$VAR$REPLICADOR', TRUE);
END^

UPDATE R$C$TB$BANCO_DADOS SET
ORIGEM = UUID,
SEQUENCIA = (SELECT MAX(SEQUENCIA) FROM R$O$TB$TRANSACAO),
UUID = UUID_TO_CHAR(GEN_UUID())^

CREATE TABLE R$D$TB$GATILHOS(NOME VARCHAR(31) NOT NULL)^

EXECUTE BLOCK AS
DECLARE NOME VARCHAR(31);
BEGIN
	FOR 
		SELECT RDB$TRIGGER_NAME FROM RDB$TRIGGERS
		WHERE RDB$SYSTEM_FLAG = 0 
		AND RDB$TRIGGER_INACTIVE = 0
		AND RDB$TRIGGER_NAME NOT SIMILAR TO 'R$(C|O|D)$TG$%'
		INTO :NOME
	DO
	BEGIN
		INSERT INTO R$D$TB$GATILHOS(NOME) VALUES(:NOME);
		EXECUTE STATEMENT 'ALTER TRIGGER ' || NOME || ' INACTIVE';
	END
END^

CREATE OR ALTER EXCEPTION R$D$EX$REPLICADOR ''^

CREATE OR ALTER TRIGGER R$D$TG$TRANSACAO_COMMIT ON TRANSACTION COMMIT AS
BEGIN
	IF (RDB$GET_CONTEXT('USER_SESSION', 'R$C$VAR$REPLICADOR') IS NULL) THEN
	BEGIN
		EXCEPTION R$D$EX$REPLICADOR
			'Banco de dados replicado' || ASCII_CHAR (13) || ASCII_CHAR (10) ||
			'Use o replicador para criar uma copia usavel deste banco de dados.';
	END 
END^
