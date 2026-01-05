DROP DATABASE riotBDD;
CREATE DATABASE riotBDD; 
USE riotBDD;
CREATE TABLE Joueur(
   id_joueur VARCHAR(50),
   pseudo VARCHAR(50),
   niveau_compte INT NOT NULL, 
   /* tous les attributs de rang de classement peuvent être null si le joueur est "non-classé" */
   rang_palier VARCHAR(20) NULL, -- Le rang est sous la forme "Emeraude", "Platine", "Argent" etc ... 
   division_palier CHAR(1) NULL, -- La division va de 4 à 1 et selon le rang elle peut être nulle 
   points_ligue INT NULL,
   PRIMARY KEY(id_joueur)
);

CREATE TABLE Match_(
   id_match VARCHAR(50),
   date_match DATETIME NOT NULL,
   duree_secondes INT NOT NULL,
   PRIMARY KEY(id_match)
);

CREATE TABLE Item(
   id_item VARCHAR(50),
   nom_item VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_item),
   UNIQUE(nom_item)
);

CREATE TABLE ModeJeu(
   id_mode VARCHAR(50),
   nom_mode VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_mode),
   UNIQUE(nom_mode)
);

CREATE TABLE Champion(
   id_champion VARCHAR(50),
   nom_affiche VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_champion)
);

CREATE TABLE Rune(
   id_rune VARCHAR(50),
   nom_arbre VARCHAR(50),
   main_rune VARCHAR(50) NOT NULL,
   arbre_principal1 VARCHAR(50) NOT NULL,
   arbre_principal2 VARCHAR(50) NOT NULL,
   arbre_principal3 VARCHAR(50) NOT NULL,
   arbre_secondaire1 VARCHAR(50) NOT NULL,
   arbre_secondaire2 VARCHAR(50) NOT NULL,
   stats1 VARCHAR(50) NOT NULL,
   stats2 VARCHAR(50) NOT NULL,
   stats3 VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_rune)
);

CREATE TABLE SkinChampion(
   id_champion VARCHAR(50),
   id_skin VARCHAR(50),
   nom_skin VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_champion, id_skin),
   FOREIGN KEY(id_champion) REFERENCES Champion(id_champion) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ItemJoueur(
   id_item VARCHAR(50),
   nom_item VARCHAR(50) NOT NULL,
   slot INT NOT NULL,
   PRIMARY KEY(id_item),
   UNIQUE(nom_item)
);

CREATE TABLE RuneJoueur(
   id_runejoueur VARCHAR(50),
   rune_principale VARCHAR(50) NOT NULL,
   rune_secondaire VARCHAR(50) NOT NULL,
   PRIMARY KEY(id_runejoueur)
);

CREATE TABLE PageStatistiqueJoueur(
   id_match VARCHAR(50),
   id_joueur VARCHAR(50),
   lane VARCHAR(10) NOT NULL,
   resultat_joueur CHAR(1) NOT NULL, /* 'V' ou 'D' ou 'R' selon victoire ou défaite ou remake */
   niveau_fin INT NOT NULL,
   kills INT NOT NULL,
   deaths INT NOT NULL,
   assists INT NOT NULL,
   cs_total INT NOT NULL,
   degats_infliges INT NOT NULL,
   score_vision INT NOT NULL,
   cs_par_minute DECIMAL(4,2) NOT NULL,
   degats_par_minute INT NOT NULL,
   vision_par_minute INT NOT NULL,
   side CHAR(1) NOT NULL, -- le side est bleu ou rouge
   PRIMARY KEY(id_match, id_joueur),
   FOREIGN KEY(id_match) REFERENCES Match_(id_match) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_joueur) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Acheter(
   id_champion VARCHAR(50),
   id_item VARCHAR(50),
   slot INT NOT NULL,	
   PRIMARY KEY(id_champion, id_item),
   FOREIGN KEY(id_champion) REFERENCES Champion(id_champion) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_item) REFERENCES Item(id_item) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE StatistiquesChamp(
   id_joueur VARCHAR(50),
   id_champion VARCHAR(50),
   id_mode VARCHAR(50),
   note CHAR(1) NOT NULL, -- note allant de 'D' à 'S'
   taux_victoire DECIMAL(5,2) NOT NULL,
   parties_jouees INT NOT NULL,
   kda_moyen DECIMAL(5,2) NOT NULL,
   taux_ban DECIMAL(5,2) NOT NULL,
   PRIMARY KEY(id_joueur, id_champion, id_mode),
   FOREIGN KEY(id_joueur) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_champion) REFERENCES Champion(id_champion) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_mode) REFERENCES ModeJeu(id_mode) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Choisir(
   id_champion VARCHAR(50),
   id_rune VARCHAR(50),
   PRIMARY KEY(id_champion, id_rune),
   FOREIGN KEY(id_champion) REFERENCES Champion(id_champion) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_rune) REFERENCES Rune(id_rune) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Ami(
   id_joueur VARCHAR(50),
   id_joueur_1 VARCHAR(50),
   PRIMARY KEY(id_joueur, id_joueur_1),
   FOREIGN KEY(id_joueur) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_joueur_1) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE,
   paire_joueurs VARCHAR(100) AS (CASE WHEN id_joueur < id_joueur_1 THEN CONCAT(id_joueur, '-', id_joueur_1) ELSE CONCAT(id_joueur_1, '-', id_joueur) END)
);

CREATE TABLE AcheterJoueur(
   id_joueur VARCHAR(50),
   id_match VARCHAR(50),
   id_item VARCHAR(50),
   PRIMARY KEY(id_joueur, id_match, id_item),
   FOREIGN KEY(id_joueur) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_match) REFERENCES Match_(id_match) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_item) REFERENCES ItemJoueur(id_item) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ChoisirJoueur(
   id_joueur VARCHAR(50),
   id_match VARCHAR(50),
   id_runejoueur VARCHAR(50),
   PRIMARY KEY(id_joueur, id_match, id_runejoueur),
   FOREIGN KEY(id_joueur) REFERENCES Joueur(id_joueur) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_match) REFERENCES Match_(id_match) ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_runejoueur) REFERENCES RuneJoueur(id_runejoueur) ON DELETE CASCADE ON UPDATE CASCADE
);
