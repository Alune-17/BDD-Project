USE riotBDD;

ALTER TABLE pagestatistiquejoueur
ADD CONSTRAINT side_check CHECK (side IN ('B','R')),
ADD CONSTRAINT lane_check CHECK (lane IN ('TOP','JNG','MID','ADC','SUP')),
ADD CONSTRAINT niveau_fin_check CHECK (niveau_fin >= 1 AND niveau_fin <= 18),
ADD CONSTRAINT statsjoueur_check CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0 AND cs_total >= 0 AND degats_infliges >= 0 AND score_vision >= 0);


ALTER TABLE ami
ADD CONSTRAINT doublon_check UNIQUE(paire_joueurs); 

ALTER TABLE PageStatistiqueJoueur
ADD CONSTRAINT resultat_check CHECK (resultat_joueur IN ('V','D','R'));

ALTER TABLE StatistiquesChamp
ADD CONSTRAINT note_check CHECK (note IN ('D','C','B','A','S')),
ADD CONSTRAINT stats_check CHECK (taux_victoire >= 0 AND kda_moyen >= 0 AND taux_ban >= 0);

