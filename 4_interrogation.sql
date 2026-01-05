USE riotBDD;

-- Joueurs de rang Émeraude ou supérieur
SELECT pseudo, rang_palier, division_palier
FROM Joueur
WHERE rang_palier IN ('Émeraude', 'Diamant', 'Maître')
ORDER BY rang_palier, division_palier;

-- Champions contenant 'a' dans leur nom
SELECT nom_affiche
FROM Champion
WHERE nom_affiche LIKE '%a%'
ORDER BY nom_affiche ASC;

--  Matchs entre Janvier 2024  et octobre 2025
SELECT id_match, date_match, duree_secondes
FROM Match_
WHERE date_match BETWEEN '2024-01-01' AND '2025-10-31'
ORDER BY date_match DESC;

-- Joueurs avec un niveau de compte supérieur à 200
SELECT pseudo, niveau_compte
FROM Joueur
WHERE niveau_compte > 200
ORDER BY niveau_compte DESC;

-- Liste distincte des lanes jouées
SELECT DISTINCT lane
FROM PageStatistiqueJoueur;

-- Moyenne de KDA par champion
SELECT id_champion, ROUND(AVG(kda_moyen), 2) AS kda_moyen_champion
FROM StatistiquesChamp
GROUP BY id_champion
ORDER BY kda_moyen_champion DESC;

-- Total de parties par mode de jeu
SELECT id_mode, SUM(parties_jouees) AS total_parties
FROM StatistiquesChamp
GROUP BY id_mode
HAVING total_parties > 20;

-- Moyenne de dégâts par lane
SELECT lane, ROUND(AVG(degats_infliges), 0) AS degats_moyens
FROM PageStatistiqueJoueur
GROUP BY lane
ORDER BY degats_moyens DESC;

-- Nombre de joueurs par rang
SELECT rang_palier, COUNT(*) AS nb_joueurs
FROM Joueur
GROUP BY rang_palier
HAVING nb_joueurs > 1;

-- Moyenne de vision par minute pour les joueurs ayant gagné (V)
SELECT resultat_joueur, ROUND(AVG(vision_par_minute), 2) AS vision_moyenne
FROM PageStatistiqueJoueur
WHERE resultat_joueur = 'V'
GROUP BY resultat_joueur;

-- Joueurs et leurs champions les plus joués
SELECT j.pseudo, c.nom_affiche, sc.parties_jouees
FROM Joueur j
INNER JOIN StatistiquesChamp sc ON j.id_joueur = sc.id_joueur
INNER JOIN Champion c ON c.id_champion = sc.id_champion
ORDER BY sc.parties_jouees DESC;

-- Liste des items achetés par champion
SELECT ch.nom_affiche AS champion, i.nom_item
FROM Acheter a
JOIN Champion ch ON ch.id_champion = a.id_champion
JOIN Item i ON i.id_item = a.id_item;

-- Joueurs et leurs amis (auto-jointure)
SELECT j1.pseudo AS joueur, j2.pseudo AS ami
FROM Ami a
JOIN Joueur j1 ON a.id_joueur = j1.id_joueur
JOIN Joueur j2 ON a.id_joueur_1 = j2.id_joueur;

-- Jointure externe gauche : joueurs et leurs statistiques
SELECT j.pseudo, sc.kda_moyen, sc.taux_victoire
FROM Joueur j
LEFT JOIN StatistiquesChamp sc ON j.id_joueur = sc.id_joueur
ORDER BY j.pseudo;

-- Matchs et les joueurs associés
SELECT m.id_match, j.pseudo, psj.kills, psj.deaths, psj.assists
FROM Match_ m
JOIN PageStatistiqueJoueur psj ON m.id_match = psj.id_match
JOIN Joueur j ON psj.id_joueur = j.id_joueur
ORDER BY m.date_match DESC;

-- Joueurs ayant déjà joué un champion avec un taux de victoire > 60%
SELECT pseudo
FROM Joueur
WHERE id_joueur IN (
    SELECT id_joueur
    FROM StatistiquesChamp
    WHERE taux_victoire > 60
);

-- Champions qui n’ont jamais été choisis
SELECT nom_affiche
FROM Champion
WHERE id_champion NOT IN (
    SELECT id_champion FROM Choisir
);

-- Joueurs ayant acheté au moins un item spécifique
SELECT pseudo
FROM Joueur
WHERE EXISTS (
    SELECT 1 FROM AcheterJoueur aj
    JOIN ItemJoueur ij ON ij.id_item = aj.id_item
    WHERE aj.id_joueur = Joueur.id_joueur
      AND ij.nom_item LIKE '%Ber%'
);

-- Champions dont le KDA moyen est supérieur à la moyenne globale
SELECT id_champion, kda_moyen
FROM StatistiquesChamp sc1
WHERE kda_moyen > (
    SELECT AVG(kda_moyen)
    FROM StatistiquesChamp
);

--  Joueurs ayant un taux de victoire supérieur à tous les autres de leur rang
SELECT j.pseudo, sc.taux_victoire
FROM Joueur j
JOIN StatistiquesChamp sc ON j.id_joueur = sc.id_joueur
WHERE sc.taux_victoire > ALL (
    SELECT taux_victoire
    FROM StatistiquesChamp s2
    WHERE s2.id_joueur <> j.id_joueur
);


/* ============================================================
   REQUÊTE 1 — Perspective “Joueur”
   Focus champions : Yasuo, Yone, Irelia
   ============================================================ */

WITH pool AS (
    SELECT 'yasuo' AS id_champion
    UNION ALL SELECT 'yone'
    UNION ALL SELECT 'irelia'
),
rang_order AS (
    SELECT 'Maître'  AS rang_palier, 1 AS ordre
    UNION ALL SELECT 'Diamant',  2
    UNION ALL SELECT 'Émeraude', 3
    UNION ALL SELECT 'Platine',  4
    UNION ALL SELECT 'Or',       5
    UNION ALL SELECT 'Argent',   6
    UNION ALL SELECT 'Bronze',   7
    UNION ALL SELECT 'Fer',      8
),
ladder_base AS (
    SELECT
        sc.id_champion,
        sc.taux_victoire,
        sc.kda_moyen,
        sc.parties_jouees,
        j.rang_palier,
        j.division_palier,
        ro.ordre
    FROM StatistiquesChamp sc
    JOIN Joueur j      ON j.id_joueur = sc.id_joueur
    JOIN rang_order ro ON ro.rang_palier = j.rang_palier
    WHERE sc.id_mode = 'mode1'
      AND sc.id_champion IN (SELECT id_champion FROM pool)
),
agg AS (
    SELECT
        id_champion,
        ROUND(AVG(taux_victoire), 4) AS winrate_moyen,
        ROUND(AVG(kda_moyen), 4)     AS kda_moyen,
        SUM(parties_jouees)          AS echantillon_total
    FROM ladder_base
    GROUP BY id_champion
),
best_rank AS (
    SELECT id_champion, MIN(ordre) AS best_ordre
    FROM ladder_base
    GROUP BY id_champion
),
best_detail AS (
    SELECT
        lb.id_champion,
        lb.rang_palier,
        MIN(lb.division_palier) AS best_division
    FROM ladder_base lb
    JOIN best_rank br
      ON br.id_champion = lb.id_champion
     AND br.best_ordre  = lb.ordre
    GROUP BY lb.id_champion, lb.rang_palier
),
items AS (
    SELECT
        a.id_champion,
        GROUP_CONCAT(CONCAT('Slot ', a.slot, ' → ', i.nom_item)
                     ORDER BY a.slot SEPARATOR ' | ') AS build_reference
    FROM Acheter a
    JOIN Item i ON i.id_item = a.id_item
    WHERE a.id_champion IN (SELECT id_champion FROM pool)
    GROUP BY a.id_champion
),
runes AS (
    SELECT
        ch.id_champion,
        GROUP_CONCAT(CONCAT(r.main_rune, ' (', r.arbre_principal1, '/', r.arbre_secondaire1, ')')
                     ORDER BY r.main_rune SEPARATOR ' | ') AS runes_core
    FROM Choisir ch
    JOIN Rune r ON r.id_rune = ch.id_rune
    WHERE ch.id_champion IN (SELECT id_champion FROM pool)
    GROUP BY ch.id_champion
)
SELECT
    p.id_champion                                        AS champion,
    a.winrate_moyen                                      AS winrate_moyen_ladder,
    a.kda_moyen                                          AS kda_moyen_ladder,
    COALESCE(a.echantillon_total, 0)                     AS nb_parties_observees,
    CASE
        WHEN bd.rang_palier IS NOT NULL
        THEN CONCAT(bd.rang_palier, ' ', COALESCE(bd.best_division, ''))
        ELSE NULL
    END                                                  AS plus_haut_palier,
    it.build_reference                                   AS build_recommande,
    ru.runes_core                                        AS runes_recommandees
FROM pool p
LEFT JOIN agg         a  ON a.id_champion  = p.id_champion
LEFT JOIN best_detail bd ON bd.id_champion = p.id_champion
LEFT JOIN items       it ON it.id_champion = p.id_champion
LEFT JOIN runes       ru ON ru.id_champion = p.id_champion
ORDER BY champion;
/* ============================================================
   REQUÊTE 2 — Perspective “Data Analyst”
   Suivi performances joueurs (mode1, high elo)
   ============================================================ */
SELECT 
    j.pseudo,
    j.rang_palier,
    j.division_palier,
    sc.id_champion,
    c.nom_affiche AS champion,
    sc.parties_jouees,
    sc.taux_victoire,
    sc.kda_moyen,
    sc.taux_ban,
    ROUND(AVG(sc.taux_victoire) OVER(), 2) AS winrate_moyen_global,
    ROUND(MAX(sc.kda_moyen) OVER(), 2)     AS kda_max_global,
    ROUND(MIN(sc.kda_moyen) OVER(), 2)     AS kda_min_global,
    ROUND(SUM(sc.parties_jouees) OVER(),0) AS total_parties_analysees,
    ROUND((sc.taux_victoire * 0.6 + sc.kda_moyen * 10 + sc.parties_jouees / 20), 2) AS score_performance
FROM Joueur j
INNER JOIN StatistiquesChamp sc ON j.id_joueur = sc.id_joueur
INNER JOIN Champion c ON c.id_champion = sc.id_champion
LEFT JOIN Choisir ch ON ch.id_champion = c.id_champion
LEFT JOIN Rune r ON r.id_rune = ch.id_rune
WHERE sc.id_mode = 'mode1'
  AND j.niveau_compte BETWEEN 150 AND 320
  AND j.rang_palier IN ('Émeraude', 'Diamant', 'Maître')
  AND sc.taux_victoire > ALL (
      SELECT AVG(taux_victoire)
      FROM StatistiquesChamp
      WHERE id_champion = sc.id_champion
  )
  AND sc.kda_moyen NOT IN (
      SELECT kda_moyen FROM StatistiquesChamp
      WHERE kda_moyen < 1.5
  )
  AND EXISTS (
      SELECT 1 FROM Acheter a WHERE a.id_champion = sc.id_champion
  )
GROUP BY j.pseudo, j.rang_palier, j.division_palier, sc.id_champion, c.nom_affiche,
         sc.parties_jouees, sc.taux_victoire, sc.kda_moyen, sc.taux_ban
HAVING AVG(sc.kda_moyen) > 2.5
   AND SUM(sc.parties_jouees) > 50
ORDER BY score_performance DESC, taux_victoire DESC;

/* ============================================================
   REQUÊTE — Détection d’anomalies / “champions broken”
   ============================================================ */
WITH
-- 1) Base ladder : mode1 + joueurs plausibles
champ_mode1 AS (
    SELECT
        sc.id_champion, sc.id_joueur,
        sc.taux_victoire, sc.kda_moyen, sc.parties_jouees, sc.taux_ban,
        j.rang_palier, j.division_palier, j.niveau_compte
    FROM StatistiquesChamp sc
    JOIN Joueur j ON j.id_joueur = sc.id_joueur
    WHERE sc.id_mode = 'mode1'
      AND j.niveau_compte BETWEEN 1 AND 1000
      AND (j.rang_palier IS NULL OR j.rang_palier IN ('Émeraude','Diamant','Maître','Platine','Or'))
),

-- 2) Moyennes globales (benchmarks)
glob AS (
    SELECT
        AVG(taux_victoire)          AS wr_avg,
        NULLIF(STDDEV_SAMP(taux_victoire),0)  AS wr_std,
        AVG(kda_moyen)              AS kda_avg,
        NULLIF(STDDEV_SAMP(kda_moyen),0)      AS kda_std,
        AVG(parties_jouees)         AS vol_avg,
        NULLIF(STDDEV_SAMP(parties_jouees),0) AS vol_std,
        AVG(taux_ban)               AS ban_avg,
        NULLIF(STDDEV_SAMP(taux_ban),0)       AS ban_std
    FROM champ_mode1
),

-- 3) Agrégats par champion
agg_base AS (
    SELECT
        cm.id_champion,
        COUNT(DISTINCT cm.id_joueur) AS nb_joueurs_distincts,
        SUM(cm.parties_jouees)       AS vol_total,
        AVG(cm.taux_victoire)        AS wr_moy,
        AVG(cm.kda_moyen)            AS kda_moy,
        AVG(cm.taux_ban)             AS ban_moy
    FROM champ_mode1 cm
    GROUP BY cm.id_champion
),

-- 4) Percentiles sur pickrate / WR / KDA
agg_champ AS (
    SELECT
        a.*,
        PERCENT_RANK() OVER (ORDER BY a.vol_total) AS p_pickrate,
        PERCENT_RANK() OVER (ORDER BY a.wr_moy)    AS p_wr,
        PERCENT_RANK() OVER (ORDER BY a.kda_moy)   AS p_kda
    FROM agg_base a
),

-- 5) Z-scores vs global
zs AS (
    SELECT
        a.id_champion,
        a.nb_joueurs_distincts, a.vol_total, a.wr_moy, a.kda_moy, a.ban_moy,
        a.p_pickrate, a.p_wr, a.p_kda,
        (a.wr_moy   - g.wr_avg)  / NULLIF(g.wr_std, 0)  AS z_wr,
        (a.kda_moy  - g.kda_avg) / NULLIF(g.kda_std, 0) AS z_kda,
        (a.vol_total- g.vol_avg) / NULLIF(g.vol_std, 0) AS z_vol,
        (a.ban_moy  - g.ban_avg) / NULLIF(g.ban_std, 0) AS z_ban
    FROM agg_champ a
    JOIN glob g ON 1=1
),

-- 6) Pages d’items
builds AS (
    SELECT
        a.id_champion,
        GROUP_CONCAT(CONCAT('Slot ', a.slot, '→', i.nom_item)
                     ORDER BY a.slot SEPARATOR ' | ') AS build_core,
        SUM(CASE WHEN i.nom_item LIKE '%Goredrinker%' THEN 1 ELSE 0 END) AS use_goredrinker,
        SUM(CASE WHEN i.nom_item LIKE '%Stride%' OR i.nom_item LIKE '%Trinity%' THEN 1 ELSE 0 END) AS use_mythic_bruiser
    FROM Acheter a
    LEFT JOIN Item i ON i.id_item = a.id_item
    GROUP BY a.id_champion
),

-- 7) Pages de runes
runes AS (
    SELECT
        ch.id_champion,
        GROUP_CONCAT(CONCAT(r.main_rune,' [',r.nom_arbre,'] (',r.arbre_principal1,'/',r.arbre_secondaire1,')')
                     ORDER BY r.main_rune SEPARATOR ' | ') AS runes_core,
        SUM(CASE WHEN r.main_rune IN ('Conqueror','Lethal Tempo','First Strike') THEN 1 ELSE 0 END) AS use_meta_keystones
    FROM Choisir ch
    LEFT JOIN Rune r ON r.id_rune = ch.id_rune
    GROUP BY ch.id_champion
),

-- 8) Flags + score d’anomalie (seuils assouplis pour petits jeux de données)
flags AS (
    SELECT
        z.id_champion,
        z.nb_joueurs_distincts, z.vol_total, z.wr_moy, z.kda_moy, z.ban_moy,
        z.z_wr, z.z_kda, z.z_vol, z.z_ban,
        z.p_pickrate, z.p_wr, z.p_kda,
        b.build_core, COALESCE(b.use_goredrinker,0) AS use_goredrinker, COALESCE(b.use_mythic_bruiser,0) AS use_mythic_bruiser,
        r.runes_core, COALESCE(r.use_meta_keystones,0) AS use_meta_keystones,

        ROUND( COALESCE(z.z_wr,0)*0.45
             + COALESCE(z.z_kda,0)*0.25
             + COALESCE(z.z_ban,0)*0.20
             + COALESCE(z.p_pickrate,0)*0.10, 3) AS anomaly_score,

        (COALESCE(z.z_wr,0)  >= 1.0)  AS flag_wr_high,
        (COALESCE(z.z_kda,0) >= 1.0)  AS flag_kda_high,
        (COALESCE(z.z_ban,0) >= 1.5 AND z.wr_moy >= (SELECT wr_avg FROM glob)) AS flag_ban_pressure,
        (COALESCE(z.p_pickrate,0) >= 0.80) AS flag_pick_spike,
        (COALESCE(b.use_goredrinker,0) >= 1) AS flag_gore_pattern,
        (COALESCE(r.use_meta_keystones,0) = 0) AS flag_offmeta_runes
    FROM zs z
    LEFT JOIN builds b ON b.id_champion = z.id_champion
    LEFT JOIN runes  r ON r.id_champion = z.id_champion
    WHERE EXISTS (SELECT 1 FROM Acheter a WHERE a.id_champion = z.id_champion)
),

-- 9) Seuil dynamique : 80e percentile si assez de lignes, sinon moyenne
seuil AS (
  SELECT
    CASE
      WHEN COUNT(*) >= 5 THEN (
        SELECT MIN(anomaly_score) FROM (
          SELECT anomaly_score,
                 PERCENT_RANK() OVER (ORDER BY anomaly_score) AS pr
          FROM flags
        ) t
        WHERE t.pr >= 0.80
      )
      ELSE (SELECT AVG(anomaly_score) FROM flags)
    END AS th
  FROM flags
)

-- 10) Sélection finale
SELECT
    f.id_champion,
    c.nom_affiche AS champion,
    f.nb_joueurs_distincts,
    f.vol_total,
    ROUND(f.wr_moy, 2)  AS wr_moy,
    ROUND(f.kda_moy, 2) AS kda_moy,
    ROUND(f.ban_moy, 2) AS ban_moy,
    ROUND(f.z_wr, 2)    AS z_wr,
    ROUND(f.z_kda, 2)   AS z_kda,
    ROUND(f.z_ban, 2)   AS z_ban,
    ROUND(f.p_pickrate, 3) AS pctile_pickrate,
    ROUND(f.p_wr, 3)       AS pctile_wr,
    ROUND(f.p_kda, 3)      AS pctile_kda,
    f.build_core,
    f.runes_core,
    f.use_goredrinker, f.use_mythic_bruiser, f.use_meta_keystones,
    f.flag_wr_high, f.flag_kda_high, f.flag_ban_pressure, f.flag_pick_spike, f.flag_gore_pattern, f.flag_offmeta_runes,
    f.anomaly_score
FROM flags f
JOIN seuil s ON 1=1
JOIN Champion c ON c.id_champion = f.id_champion
WHERE
    (
      f.anomaly_score >= s.th
      OR f.flag_wr_high
      OR f.flag_kda_high
      OR f.flag_ban_pressure
      OR f.flag_pick_spike
      OR (f.flag_gore_pattern AND f.wr_moy >= (SELECT wr_avg FROM glob))
      OR (f.flag_offmeta_runes AND f.kda_moy >= (SELECT kda_avg FROM glob))
    )
ORDER BY
    f.anomaly_score DESC,
    f.z_wr DESC,
    f.z_kda DESC,
    f.z_ban DESC,
    f.vol_total DESC;