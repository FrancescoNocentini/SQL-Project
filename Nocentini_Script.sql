#Creazione db
DROP DATABASE IF EXISTS progetto_nocentini;
CREATE DATABASE IF NOT EXISTS progetto_nocentini;
USE progetto_nocentini;

#Cancellazione tabelle per sicurezza
DROP TABLE IF EXISTS Cliente;
DROP TABLE IF EXISTS Ordine;
DROP TABLE IF EXISTS Ordinato;
DROP TABLE IF EXISTS Libro;
DROP TABLE IF EXISTS Composizione;
DROP TABLE IF EXISTS Casa_Editrice;
DROP TABLE IF EXISTS Pubblicato;
DROP TABLE IF EXISTS Autore;
DROP TABLE IF EXISTS Scritto;
DROP VIEW IF EXISTS OrdiniPerCliente;
DROP VIEW IF EXISTS LibriPerOrdine;

#Creazione tabelle
CREATE TABLE Cliente(
	codC INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(20) NOT NULL,
    cognome VARCHAR(20) NOT NULL,
    sesso ENUM('M','F'),
    data_nascita DATE NOT NULL
)ENGINE=INNODB;

CREATE TABLE Ordine(
	codO INT PRIMARY KEY AUTO_INCREMENT,
    prezzo_totale FLOAT NOT NULL
)ENGINE=INNODB;

CREATE TABLE Ordinato(
	codC INT,	#AUTO_INCREMENT ?
    codO INT,	#AUTO_INCREMENT ?
    PRIMARY KEY(codC,codO),
    FOREIGN KEY(codC) REFERENCES Cliente(codC),	#Ci va on update?
    FOREIGN KEY(codO) REFERENCES Ordine(codO),	#Ci va on update?
	data_ordine DATE NOT NULL
)ENGINE=INNODB;

CREATE TABLE Libro(
	codL VARCHAR(14) PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    anno_pubblicazione INT NOT NULL,
    prezzo FLOAT NOT NULL,
    disponibilità INT NOT NULL
)ENGINE=INNODB;

CREATE TABLE Composizione(
	codO INT,	#AUTO_INCREMENT ?
    codL VARCHAR(14),
    PRIMARY KEY(codO,codL),
	FOREIGN KEY(codO) REFERENCES Ordine(codO),	#Ci va on update?
    FOREIGN KEY(codL) REFERENCES Libro(codL),		#Ci va on update?
    data_ordine DATE NOT NULL,
    quantità INT NOT NULL
)ENGINE=INNODB;

CREATE TABLE Casa_Editrice(
	codEd INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(20) NOT NULL
)ENGINE=INNODB;

CREATE TABLE Pubblicato(
	codL VARCHAR(14),	#AUTO_INCREMENT ?
    codEd INT,	#AUTO_INCREMENT ?
    PRIMARY KEY(codEd,codL),
    FOREIGN KEY(codL) REFERENCES Libro(codL),			#Ci va on update?
	FOREIGN KEY(codEd) REFERENCES Casa_Editrice(codEd)	#Ci va on update?
)ENGINE=INNODB;

CREATE TABLE Autore(
	codA INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(20) NOT NULL,
    cognome VARCHAR(20) NOT NULL
)ENGINE=INNODB;

CREATE TABLE Scritto(
	codL VARCHAR(14),	#AUTO_INCREMENT ?
    codA INT,	#AUTO_INCREMENT ?
    PRIMARY KEY(codL,codA),
	FOREIGN KEY(codL) REFERENCES Libro(codL),	#Ci va on update?
    FOREIGN KEY(codA) REFERENCES Autore(codA)	#Ci va on update?
)ENGINE=INNODB;

#Popolamento
set global local_infile=1;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiClienti.txt' INTO TABLE Cliente FIELDS TERMINATED BY ',' IGNORE 4 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiOrdini.txt' INTO TABLE Ordine FIELDS TERMINATED BY ',' IGNORE 3 LINES;	#warning ok
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiOrdinati.txt' INTO TABLE Ordinato FIELDS TERMINATED BY ',' IGNORE 2 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiLibri.txt' INTO TABLE Libro FIELDS TERMINATED BY ',' IGNORE 3 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiComposizioni.txt' INTO TABLE Composizione FIELDS TERMINATED BY ',' IGNORE 4 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiCasaEd.txt' INTO TABLE Casa_Editrice FIELDS TERMINATED BY ',' IGNORE 4 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiPubblicati.txt' INTO TABLE Pubblicato FIELDS TERMINATED BY ',' IGNORE 3 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiAutori.txt' INTO TABLE Autore FIELDS TERMINATED BY ',' IGNORE 4 LINES;
LOAD DATA LOCAL INFILE 'C:/Users/lance/Desktop/Progetto Nocentini/DatiScritti.txt' INTO TABLE Scritto FIELDS TERMINATED BY ',' IGNORE 3 LINES;
select * from Cliente;
select * from Ordine;
select * from Ordinato;
select * from Libro;
select * from Composizione;
select * from Casa_Editrice;
select * from Pubblicato;
select * from Autore;
select * from Scritto;

#codice clienti che hanno effettuato ordini nel 2021
select codO from Ordinato where data_ordine >= "2021/01/01";
#vista con codice cliente e numero di ordini effettuati
create view OrdiniPerCliente as select count(*) as cont, codC from Ordinato group by codC;
#codice cliente che ha effettuato più ordini
select max(cont), codC from OrdiniPerCliente;
#numero ordini effettuati in totale
select sum(cont) from OrdiniPerCliente;
#quantità ordini effettuati da clienti nati dal 2000 in poi
select sum(cont) from OrdiniPerCliente natural join Cliente where data_nascita >= "2000/01/01";
#codice, nome, quantita' libro piu' acquistato
create view LibriPerOrdine as select quantità as qta, codL, codO, data_ordine from Composizione group by codL;
select codL, nome, max(qta) from LibriPerOrdine natural join Libro;
#nome casa editrice che ha venduto più libri
select * from LibriPerOrdine natural join Pubblicato group by codL;	#perche' se faccio group by non raggruppa ma mi taglia risultati?
#dopo il group by fare la somma delle quantita' e prendere il max
select * from LibriPerOrdine;
select * from Composizione;
#procedura inserimento nuovo ordine, devi aggiornare composizione, ordine ed ordinato, in input codC, data_ordine, quantità1, quantità2, quantità3, codL1, codL2, codL3
#codO è progressivo, prezzo_totale lo calcolo nella procedura

DELIMITER //
DROP PROCEDURE IF EXISTS progetto_nocentini.inserimentoOrdine //
CREATE PROCEDURE progetto_nocentini.inserimentoOrdine(IN codC INT,IN data_ordine DATE,IN quantita1 INT,IN quantita2 INT,IN quantita3 INT,IN codL1 VARCHAR(14),IN codL2 VARCHAR(14),IN codL3 VARCHAR(14))
#se codC e/o data sono NULL allora devo interrompere la procedura, se una quantità ed un codL sono pari a 0 allora vado avanti, ho ordinato solo i libri precendenti, max 3
#dovrei controllare anche di aver messo una data > dell'ultima presente in ordine, prendere la data di max codO e controllare o provare con max(data)
#devo calcolare il prezzo totale
BEGIN
	DECLARE tmp1 FLOAT;
	DECLARE tmp2 FLOAT;
	DECLARE tmp3 FLOAT;
    DECLARE prezzo_tot FLOAT;
    DECLARE codOrdine INT;
    
    SET tmp1 = 0;
	SET tmp2 = 0;
	SET tmp3 = 0;
    
    IF(quantita1 > 0) THEN SELECT prezzo FROM Libro where codL = codL1 INTO tmp1; END IF;
	IF(quantita2 > 0) THEN SELECT prezzo FROM Libro where codL = codL2 INTO tmp2; END IF;
	IF(quantita3 > 0) THEN SELECT prezzo FROM Libro where codL = codL3 INTO tmp3; END IF;
	
    SET prezzo_tot = tmp1 * quantita1 + tmp2 * quantita2 + tmp3 * quantita3;
    #aggiungo la riga nella tabella Ordine
	INSERT INTO Ordine VALUES(prezzo_tot);
	#aggiungo le eventuali righe nella tabella Composizione
    SELECT codO FROM Ordine WHERE codO = max(codO) INTO codOrdine;
	IF(quantita1 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL1, data_ordine ,quantita1); END IF;
	IF(quantita2 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL2, data_ordine ,quantita2); END IF;
	IF(quantita3 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL3, data_ordine ,quantita3); END IF;
    #aggiungo la riga nella tabella Ordinato concludendo cosi gli inserimenti da fare nelle tabelle per aggiungere correttamente un ordine
	INSERT INTO Ordinato VALUES(codC, codOrdine, data_ordine);
END //
DELIMITER ;

CALL progetto_nocentini.inserimentoOrdine(1,"2021/06/27",2,0,0,9788850334384,0,0);
/*
DELIMITER $$
DROP PROCEDURE IF EXISTS progetto_nocentini.inserimento_ordine $$
CREATE PROCEDURE progetto_nocentini.inserimento_ordine(codC INT,data_ordine DATE,quantita1 INT,quantita2 INT,quantita3 INT,codL1 VARCHAR(14),codL2 VARCHAR(14),codL3 VARCHAR(14))
#se codC e/o data sono NULL allora devo interrompere la procedura, se una quantità ed un codL sono pari a 0 allora vado avanti, ho ordinato solo i libri precendenti, max 3
#dovrei controllare anche di aver messo una data > dell'ultima presente in ordine, prendere la data di max codO e controllare o provare con max(data)
#devo calcolare il prezzo totale
BEGIN
DECLARE tmp1 FLOAT;
DECLARE tmp2 FLOAT;
DECLARE tmp3 FLOAT;
SET tmp1 = 0;
SET tmp2 = 0;
SET tmp3 = 0;
IF(quantita1 > 0) THEN SELECT prezzo FROM Libro where codL = codL1 INTO tmp1;
IF(quantita2 > 0) THEN SELECT prezzo FROM Libro where codL = codL2 INTO tmp2;
IF(quantita3 > 0) THEN SELECT prezzo FROM Libro where codL = codL3 INTO tmp3;
DECLARE prezzo_tot FLOAT;
SET prezzo_tot = tmp1 * quantita1 + tmp2 * quantita2 + tmp3 * quantita3;
#aggiungo la riga nella tabella Ordine
INSERT INTO Ordine VALUES(prezzo_tot);
#aggiungo le eventuali righe nella tabella Composizione
DECLARE codOrdine INT &&
SELECT codO FROM Ordine WHERE codO = max(codO) INTO codOrdine;
IF(quantita1 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL1, data_ordine ,quantita1);
IF(quantita2 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL2, data_ordine ,quantita2);
IF(quantita3 > 0) THEN INSERT INTO Composizione VALUES(codOrdine, codL3, data_ordine ,quantita3);
#aggiungo la riga nella tabella Ordinato concludendo cosi gli inserimenti da fare nelle tabelle per aggiungere correttamente un ordine
INSERT INTO Ordinato VALUES(codC, codOrdine, data_ordine);
END
DELIMITER $$
CALL progetto_nocentini.inserimento_ordine(1,2021/06/27,2,0,0,9788850334384,0,0);
*/