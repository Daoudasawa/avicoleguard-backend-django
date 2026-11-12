const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle, AlignmentType, LevelFormat, PageBreak,
  Header, Footer, PageNumber, convertInchesToTwip
} = require("docx");

const fs = require("fs");

// ---------- helpers ----------

const COLOR_PRIMARY = "2E5339";   // vert foncé (thème élevage)
const COLOR_ACCENT = "8B5E34";    // brun terre
const COLOR_LIGHT = "EFF3EC";
const COLOR_WARN = "9C4221";

function H1(text) {
  return new Paragraph({
    text,
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 400, after: 200 },
  });
}
function H2(text) {
  return new Paragraph({
    text,
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 280, after: 140 },
  });
}
function H3(text) {
  return new Paragraph({
    text,
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 200, after: 100 },
  });
}
function P(text, opts = {}) {
  return new Paragraph({
    children: [new TextRun({ text, ...opts })],
    spacing: { after: 160 },
  });
}
function PB(runs) {
  // runs = array of {text, bold, italic, color}
  return new Paragraph({
    children: runs.map(r => new TextRun(r)),
    spacing: { after: 160 },
  });
}
function Bullet(text, level = 0) {
  return new Paragraph({
    text,
    bullet: { level },
    spacing: { after: 80 },
  });
}
function Note(text) {
  return new Paragraph({
    children: [new TextRun({ text: "À VALIDER PAR LE TECHNICIEN EN ÉLEVAGE ET SANTÉ ANIMALE : " + text, italics: true, color: COLOR_WARN })],
    spacing: { after: 160 },
  });
}
function Quote(text) {
  return new Paragraph({
    children: [new TextRun({ text, italics: true })],
    indent: { left: 360 },
    border: { left: { style: BorderStyle.SINGLE, size: 12, color: COLOR_PRIMARY, space: 8 } },
    spacing: { after: 160 },
  });
}

function cell(text, opts = {}) {
  const { bold = false, width, shading, color } = opts;
  return new TableCell({
    width: width ? { size: width, type: WidthType.DXA } : undefined,
    shading: shading ? { type: ShadingType.CLEAR, fill: shading } : undefined,
    margins: { top: 80, bottom: 80, left: 100, right: 100 },
    children: [new Paragraph({ children: [new TextRun({ text, bold, color })] })],
  });
}

function makeTable(headers, rows, widths) {
  const totalWidth = widths.reduce((a, b) => a + b, 0);
  const headerRow = new TableRow({
    tableHeader: true,
    children: headers.map((h, i) => cell(h, { bold: true, width: widths[i], shading: COLOR_PRIMARY, color: "FFFFFF" })),
  });
  const bodyRows = rows.map((r, idx) =>
    new TableRow({
      children: r.map((c, i) => cell(c, { width: widths[i], shading: idx % 2 === 0 ? COLOR_LIGHT : "FFFFFF" })),
    })
  );
  return new Table({
    width: { size: totalWidth, type: WidthType.DXA },
    columnWidths: widths,
    rows: [headerRow, ...bodyRows],
  });
}

function Spacer(h = 200) {
  return new Paragraph({ text: "", spacing: { after: h } });
}

function PageBreakP() {
  return new Paragraph({ children: [new PageBreak()] });
}

// ---------- TITLE PAGE ----------

const titlePage = [
  new Paragraph({ text: "", spacing: { after: 1600 } }),
  new Paragraph({
    children: [new TextRun({ text: "AVICOLEGUARD", bold: true, size: 64, color: COLOR_PRIMARY })],
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "CAHIER DES CHARGES MÉTIER", bold: true, size: 36, color: COLOR_ACCENT })],
    alignment: AlignmentType.CENTER,
    spacing: { after: 100 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "Document de présentation et de collaboration destiné au", italics: true, size: 24 })],
    alignment: AlignmentType.CENTER,
    spacing: { after: 20 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "Technicien en Élevage et Santé Animale", bold: true, italics: true, size: 26, color: COLOR_PRIMARY })],
    alignment: AlignmentType.CENTER,
    spacing: { after: 1000 },
  }),
  new Paragraph({ text: "", spacing: { after: 1000 } }),
  new Paragraph({
    children: [new TextRun({ text: "Version : 1.0 (rédigée à partir du cahier des charges technique final)", size: 22 })],
    alignment: AlignmentType.CENTER, spacing: { after: 80 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "Date : Septembre 2026", size: 22 })],
    alignment: AlignmentType.CENTER, spacing: { after: 80 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "Porteur du projet : Daouda", size: 22 })],
    alignment: AlignmentType.CENTER, spacing: { after: 80 },
  }),
  new Paragraph({
    children: [new TextRun({ text: "Domaine : Élevage avicole et santé animale — Burkina Faso", size: 22 })],
    alignment: AlignmentType.CENTER, spacing: { after: 80 },
  }),
];

// ---------- BODY ----------

const body = [];

// 1. PRÉSENTATION
body.push(H1("1. Présentation du projet"));
body.push(P("AvicoleGuard est un projet d'application mobile destinée à accompagner les acteurs de l'aviculture : éleveurs, techniciens en élevage et santé animale, vétérinaires, responsables de coopératives et administrateurs de la plateforme. Il est pensé en premier lieu pour le Burkina Faso, avec l'ambition d'être utilisable ensuite dans d'autres pays de la région."));
body.push(P("Le projet est développé parce que le suivi sanitaire des élevages avicoles familiaux et semi-intensifs reste, dans la grande majorité des cas, manuel ou absent : cahier papier, mémoire de l'éleveur, ou aucun suivi du tout. Cela retarde la détection des problèmes de santé et fragilise les décisions de l'éleveur (alimentation, mortalité, croissance)."));
body.push(P("L'objectif général est d'aider l'éleveur à mieux suivre ses volailles au quotidien, à être alerté plus tôt en cas d'anomalie, et à être mis en relation plus facilement avec un technicien ou un vétérinaire lorsque cela est nécessaire — tout en restant utilisable même là où la connexion internet est faible ou absente."));

// 2. CONTEXTE
body.push(H1("2. Contexte"));
body.push(P("Le secteur de l'élevage représente une part importante de l'économie et de l'emploi au Burkina Faso, et l'aviculture en constitue une composante majeure. Le secteur reste dominé par de petites exploitations familiales."));
body.push(Bullet("L'élevage contribue à environ 12 % du PIB national et occupe près de 72 % de la population active ; l'aviculture concentre près de la moitié du cheptel national du pays (source : Agence Ecofin, 2025)."));
body.push(Bullet("Selon la FAO (2018), les moyens de subsistance liés à l'aviculture représenteraient l'équivalent de 35 millions de dollars US, soit environ 27,2 % du PIB de la filière élevage."));
body.push(Bullet("La maladie de Newcastle est citée comme une cause importante de pertes, et les intrants (aliments, poussins, vaccins) restent coûteux et en grande partie importés."));
body.push(P("Les difficultés recensées à ce stade concernent principalement : l'absence d'outils de suivi adaptés au contexte (fonctionnement sans connexion, simplicité, coût), un accès limité aux vétérinaires et techniciens en zone rurale, et une détection tardive des anomalies sanitaires faute d'historique exploitable."));
body.push(Note("le nombre exact d'éleveurs actifs, la répartition par taille d'exploitation (familiale / semi-intensive / intensive) et le taux d'équipement en smartphone de ce public ne sont pas connus avec précision à ce stade ; une vérification terrain reste nécessaire."));

// 3. PROBLÉMATIQUE
body.push(H1("3. Problématique"));
body.push(P("Le problème central est le suivi sanitaire majoritairement manuel ou absent des élevages. Concrètement, cela se traduit par des difficultés à :"));
body.push(Bullet("organiser le suivi des volailles au jour le jour ;"));
body.push(Bullet("enregistrer et retrouver les informations (mortalité, observations, opérations sanitaires) ;"));
body.push(Bullet("surveiller la mortalité de façon structurée ;"));
body.push(Bullet("détecter à temps une anomalie (comportement, alimentation, croissance) ;"));
body.push(Bullet("suivre la consommation d'eau et d'aliment ;"));
body.push(Bullet("suivre la croissance ou la production dans le temps ;"));
body.push(Bullet("conserver un historique sanitaire exploitable, notamment pour un professionnel sollicité en dehors de l'application."));
body.push(P("Ces difficultés retardent la réaction face aux maladies et conduisent à des décisions prises sans données fiables, avec un impact direct sur les pertes de cheptel et la rentabilité de l'éleveur."));

// 4. OBJECTIF GÉNÉRAL
body.push(H1("4. Objectif général"));
body.push(P("AvicoleGuard vise à aider les éleveurs à :"));
body.push(Bullet("mieux suivre leurs lots de volailles au quotidien ;"));
body.push(Bullet("mieux organiser et conserver leurs données d'élevage ;"));
body.push(Bullet("détecter certaines anomalies plus tôt grâce à une analyse automatique des données saisies ;"));
body.push(Bullet("recevoir des alertes classées par niveau d'importance ;"));
body.push(Bullet("améliorer le suivi sanitaire général de leurs élevages ;"));
body.push(Bullet("faciliter la mise en relation avec un technicien ou un vétérinaire en cas de besoin."));

// 5. OBJECTIFS SPÉCIFIQUES
body.push(H1("5. Objectifs spécifiques"));
body.push(Bullet("Faciliter le suivi des exploitations et des lots de volailles."));
body.push(Bullet("Permettre l'enregistrement des données quotidiennes (eau, aliment, poids, température)."));
body.push(Bullet("Suivre la mortalité, avec possibilité de corriger une erreur de saisie."));
body.push(Bullet("Enregistrer des observations sanitaires (signes visibles chez les animaux)."));
body.push(Bullet("Identifier certaines anomalies à partir des données enregistrées."));
body.push(Bullet("Générer des alertes classées par niveau de risque."));
body.push(Bullet("Faciliter l'accès à un technicien ou à un vétérinaire via une demande d'assistance."));
body.push(Bullet("Fournir des contenus éducatifs sur les bonnes pratiques d'élevage."));
body.push(Bullet("Améliorer la traçabilité des informations (rien n'est supprimé sans laisser de trace)."));
body.push(Bullet("Fonctionner même sans connexion internet pour les opérations essentielles du terrain."));

// 6. UTILISATEURS
body.push(H1("6. Utilisateurs du projet"));

body.push(H2("6.1 L'éleveur"));
body.push(P("L'éleveur est l'utilisateur principal de l'application. Le document distingue trois profils, dont les besoins diffèrent :"));
body.push(Bullet("Éleveur débutant : besoin d'apprendre les bonnes pratiques, risque de ne pas reconnaître les signes avant-coureurs d'un problème, a besoin de contenus éducatifs et d'alertes très explicites."));
body.push(Bullet("Éleveur expérimenté : veut gagner du temps par rapport à un suivi déjà fait mentalement ou sur papier, souhaite une saisie rapide (moins de 2 minutes par jour)."));
body.push(Bullet("Éleveur professionnel (plusieurs lots/exploitations) : veut piloter la performance globale de ses lots et réduire les pertes."));
body.push(P("L'éleveur peut notamment : créer son exploitation, enregistrer ses lots, enregistrer le suivi quotidien, déclarer une mortalité, enregistrer une observation, consulter les alertes et recommandations, et demander de l'assistance à un professionnel."));

body.push(H2("6.2 Le technicien en élevage et santé animale"));
body.push(P("Le technicien est un acteur important du projet, dont l'expertise conditionne la qualité et la pertinence de l'ensemble du suivi sanitaire proposé aux éleveurs. Il peut notamment participer à :"));
body.push(Bullet("l'accompagnement technique des éleveurs au quotidien ;"));
body.push(Bullet("l'amélioration des pratiques d'élevage ;"));
body.push(Bullet("l'analyse des informations collectées (tendances, historique d'un lot) ;"));
body.push(Bullet("l'interprétation des anomalies signalées par l'application ;"));
body.push(Bullet("la sensibilisation des éleveurs à la prévention et à la biosécurité ;"));
body.push(Bullet("l'amélioration des performances d'élevage (croissance, production)."));
body.push(P("Dans l'application, le technicien reçoit les demandes d'assistance des éleveurs, consulte l'historique complet du lot concerné avant de répondre, et peut valider ou corriger les recommandations générées automatiquement."));

body.push(H2("6.3 Le vétérinaire"));
body.push(P("Le vétérinaire intervient dans les domaines qui relèvent d'une compétence médicale et vétérinaire : diagnostic d'une maladie, décision de traitement, prescription. Le système ne remplace à aucun moment le vétérinaire ; il vise seulement à lui transmettre un historique structuré du lot pour qu'il puisse intervenir plus rapidement et de façon mieux informée."));

body.push(H2("6.4 L'administrateur"));
body.push(P("L'administrateur gère le fonctionnement général de la plateforme : comptes utilisateurs, contenus éducatifs, et paramètres des règles d'alerte. Son rôle n'a pas d'impact direct sur le travail de terrain de l'éleveur ou du technicien."));

// 7. RÔLE DU TECHNICIEN
body.push(H1("7. Rôle du technicien en élevage et santé animale"));
body.push(P("Cette section est particulièrement importante : le technicien est sollicité pour apporter son expertise métier et contribuer à la définition de plusieurs éléments du projet, présentés ci-dessous."));

body.push(H2("7.1 Les informations à collecter dans un élevage"));
body.push(P("À définir avec le technicien, parmi les informations envisagées :"));
body.push(Bullet("type d'élevage (bâtiment fermé, plein air, mixte) ;"));
body.push(Bullet("type de production (chair, ponte, reproduction) ;"));
body.push(Bullet("nombre de volailles ;"));
body.push(Bullet("race ou souche ;"));
body.push(Bullet("âge du lot ;"));
body.push(Bullet("date d'arrivée ;"));
body.push(Bullet("origine des animaux (couvoir, fournisseur, autre éleveur)."));
body.push(Note("confirmer lesquelles de ces informations sont réellement indispensables et lesquelles peuvent être omises sans perte de valeur pour le suivi sanitaire."));

body.push(H2("7.2 Les informations concernant les lots"));
body.push(P("Un lot regroupe un ensemble de volailles suivies ensemble. Les informations envisagées sont : effectif initial, effectif actuel (mis à jour automatiquement selon la mortalité), date d'arrivée, âge, souche, type de production, et statut du lot (actif ou clôturé)."));
body.push(Note("préciser si le type de production (chair / ponte / reproduction) doit être obligatoire dès la création du lot, car il conditionne les indicateurs de suivi pertinents (voir section 13)."));

body.push(H2("7.3 Le suivi quotidien"));
body.push(P("Les données actuellement envisagées pour le suivi quotidien sont : consommation d'eau, consommation d'aliment, poids moyen, et température."));
body.push(P("Le technicien doit aider à déterminer :"));
body.push(Bullet("quelles données sont réellement importantes pour détecter un problème sanitaire ;"));
body.push(Bullet("quelles données sont faciles à collecter par un éleveur sans équipement particulier ;"));
body.push(Bullet("quelles données sont adaptées à un petit élevage familial ;"));
body.push(Bullet("quelles données sont plus adaptées à un élevage professionnel."));
body.push(Note("la température est difficile à mesurer sans thermomètre pour un petit éleveur ; le poids moyen nécessite une balance et peut être demandé moins souvent qu'une fois par jour — le rythme réaliste de chaque mesure reste à confirmer avec le technicien."));

// 8. MORTALITÉ
body.push(H1("8. Suivi de la mortalité"));
body.push(P("Le système permet d'enregistrer une déclaration de mortalité avec :"));
body.push(Bullet("la date ;"));
body.push(Bullet("le nombre de volailles mortes ;"));
body.push(Bullet("une cause présumée, si l'éleveur dispose de cette information ;"));
body.push(Bullet("des observations éventuelles associées."));
body.push(Quote("Une cause présumée enregistrée par l'éleveur ne constitue pas un diagnostic vétérinaire."));
body.push(P("Une déclaration erronée peut être corrigée ou annulée par l'éleveur, avec un motif obligatoire ; l'effectif du lot est alors recalculé automatiquement, et l'annulation reste toujours visible dans l'historique (rien n'est supprimé silencieusement)."));
body.push(P("Le technicien doit aider à déterminer les informations réellement utiles lors d'une déclaration de mortalité, par exemple :"));
body.push(Bullet("s'il est utile de guider la « cause présumée » par une liste de circonstances observées (mort brutale sans signe, mort après signes respiratoires ou digestifs, accident) plutôt qu'un champ totalement libre ;"));
body.push(Bullet("si l'âge du lot au moment de la mortalité doit être mis en avant, pour mieux interpréter chaque déclaration."));

// 9. OBSERVATIONS SANITAIRES
body.push(H1("9. Observations sanitaires"));
body.push(P("L'application permet à l'éleveur d'enregistrer des observations sanitaires, c'est-à-dire des signes visibles chez les animaux. Les catégories actuellement prévues sont :"));
body.push(Bullet("comportement inhabituel ;"));
body.push(Bullet("problèmes respiratoires ;"));
body.push(Bullet("problèmes liés à l'alimentation ;"));
body.push(Bullet("problèmes digestifs ;"));
body.push(Bullet("problèmes de plumage ;"));
body.push(Bullet("problèmes locomoteurs ;"));
body.push(Bullet("autres observations."));
body.push(Quote("L'application enregistre des observations et des signes observables. Elle ne diagnostique pas automatiquement une maladie."));
body.push(P("Le technicien doit participer à la définition d'une liste simple, compréhensible et utile de signes concrets à proposer à l'éleveur dans chaque catégorie. Exemples de signes observables (et non de maladies) :"));
body.push(Bullet("respiratoire : toux, éternuements, respiration bruyante ou difficile, écoulement au niveau du nez ou des yeux ;"));
body.push(Bullet("digestif : diarrhée, fientes d'aspect anormal, baisse d'appétit ;"));
body.push(Bullet("comportement : abattement, plumes hérissées, isolement d'un individu, agitation inhabituelle ;"));
body.push(Bullet("locomoteur : boiterie, difficulté à se déplacer ;"));
body.push(Bullet("plumage/peau : plumes ternes, lésions visibles sur la peau."));
body.push(Note("valider et compléter cette liste de signes observables avec le technicien, en veillant à ne jamais introduire un nom de maladie parmi les choix proposés à l'éleveur."));

// 10. SANTÉ ANIMALE
body.push(H1("10. Suivi de la santé animale"));
body.push(P("Le système permet de planifier et d'enregistrer certaines opérations sanitaires courantes : vaccination, désinfection, traitement, vermifugation, visite d'un professionnel."));
body.push(P("Le technicien doit contribuer à identifier :"));
body.push(Bullet("les opérations réellement importantes à suivre pour ce type d'élevage ;"));
body.push(Bullet("les informations à enregistrer pour chaque opération (date prévue, date réalisée, type, statut) ;"));
body.push(Bullet("les besoins réels des éleveurs selon leur profil (débutant, expérimenté, professionnel)."));
body.push(Quote("Ce document ne définit aucun protocole sanitaire. Les programmes de vaccination ou de traitement dépendent de l'espèce, de la souche, de la zone, du contexte sanitaire local, et doivent être définis et validés par des professionnels compétents."));

// 11. BIOSÉCURITÉ
body.push(H1("11. Biosécurité"));
body.push(P("La biosécurité est un enjeu important pour limiter l'introduction et la propagation des maladies dans un élevage. Le technicien doit contribuer à identifier les bonnes pratiques pertinentes à intégrer dans l'application, parmi des domaines tels que :"));
body.push(Bullet("nettoyage ;"));
body.push(Bullet("désinfection (déjà prévue comme type d'opération sanitaire) ;"));
body.push(Bullet("gestion des visiteurs et des véhicules ;"));
body.push(Bullet("gestion des animaux morts ;"));
body.push(Bullet("entretien des équipements ;"));
body.push(Bullet("séparation des lots ;"));
body.push(Bullet("hygiène générale de l'exploitation."));
body.push(P("À ce stade, seule la désinfection est couverte par l'application. Une liste de vérification (« checklist ») complète de biosécurité est envisagée pour une version ultérieure, une fois qu'un référentiel aura été validé avec un expert avicole."));
body.push(Note("indiquer quelles pratiques de biosécurité devraient être suivies dès la première version, et lesquelles peuvent raisonnablement attendre une version ultérieure."));

// 12. ALIMENTATION
body.push(H1("12. Alimentation"));
body.push(P("Le suivi de l'alimentation est actuellement limité à la consommation quotidienne (quantité distribuée). Le technicien doit aider à déterminer les informations importantes à ajouter, parmi :"));
body.push(Bullet("type d'aliment (par exemple : démarrage, croissance, finition, ponte) ;"));
body.push(Bullet("quantité distribuée ;"));
body.push(Bullet("consommation observée ;"));
body.push(Bullet("fréquence de distribution ;"));
body.push(Bullet("stock d'aliments disponible."));
body.push(Note("préciser si la distinction entre types d'aliments (démarrage/croissance/finition/ponte) apporte une valeur suffisante pour être incluse dès la première version, ou si elle peut être simplifiée."));

// 13. PRODUCTION
body.push(H1("13. Suivi de la production"));
body.push(P("Les indicateurs de performance pertinents varient selon le type de production. Le document technique actuel ne distingue pas encore ce type de production au niveau du lot, ce qui limite la pertinence du suivi proposé."));
body.push(H3("Poulets de chair"));
body.push(Bullet("effectif ;"));
body.push(Bullet("poids moyen et croissance ;"));
body.push(Bullet("consommation alimentaire ;"));
body.push(Bullet("mortalité."));
body.push(H3("Poules pondeuses"));
body.push(Bullet("effectif ;"));
body.push(Bullet("nombre d'œufs pondus (indicateur actuellement absent du suivi quotidien) ;"));
body.push(Bullet("taux de ponte ;"));
body.push(Bullet("mortalité ;"));
body.push(Bullet("consommation alimentaire."));
body.push(Note("confirmer la nécessité d'ajouter un suivi de la production d'œufs pour les lots de pondeuses, et d'introduire un « type de production » sur chaque lot afin d'afficher les bons indicateurs selon le cas."));

// 14. DÉTECTION DES ANOMALIES
body.push(H1("14. Détection des anomalies"));
body.push(P("L'application analyse automatiquement certaines informations enregistrées par l'éleveur, par exemple :"));
body.push(Bullet("une augmentation inhabituelle de la mortalité ;"));
body.push(Bullet("une baisse inhabituelle de la consommation d'eau ou d'aliment ;"));
body.push(Bullet("des observations sanitaires répétées ;"));
body.push(Bullet("une évolution inhabituelle du poids."));
body.push(P("Lorsqu'une situation sort de la normale, une alerte peut être générée."));
body.push(Quote("Une alerte ne constitue pas un diagnostic. Elle indique uniquement qu'une situation inhabituelle ou potentiellement préoccupante nécessite une attention."));
body.push(P("Pour éviter de multiplier des alertes inutiles (« fausses alertes »), le système compare les données à une tendance sur plusieurs jours plutôt qu'à une seule mesure, tient compte de la quantité d'historique déjà disponible sur le lot, et évite de répéter la même alerte pour le même problème dans les 24 heures suivantes, sauf si la situation s'aggrave réellement."));

// 15. ALERTES
body.push(H1("15. Alertes"));
body.push(P("Les alertes sont classées selon quatre niveaux :"));
body.push(Bullet("Information — donnée à surveiller, sans caractère préoccupant ;"));
body.push(Bullet("Attention — première anomalie détectée ;"));
body.push(Bullet("Préoccupant — anomalie confirmée ou répétée ;"));
body.push(Bullet("Critique — situation nécessitant une action rapide."));
body.push(P("Le technicien doit aider à déterminer :"));
body.push(Bullet("les situations qui doivent réellement déclencher une alerte ;"));
body.push(Bullet("les informations nécessaires pour juger correctement de la gravité d'une situation ;"));
body.push(Bullet("la priorité relative des différentes alertes possibles ;"));
body.push(Bullet("les actions générales à recommander à chaque niveau."));
body.push(Note("aucun seuil chiffré (par exemple : à partir de combien de morts par jour une alerte doit se déclencher) n'est encore fixé dans ce document ; ces seuils doivent être définis avec le technicien avant tout déploiement réel."));

// 16. RECOMMANDATIONS
body.push(H1("16. Recommandations"));
body.push(P("Lorsqu'une alerte est générée, l'application propose une recommandation générale. Le système peut recommander, par exemple, de :"));
body.push(Bullet("vérifier certaines conditions d'élevage (ventilation, propreté, densité) ;"));
body.push(Bullet("observer plus attentivement les animaux ;"));
body.push(Bullet("vérifier l'alimentation ;"));
body.push(Bullet("vérifier l'accès à l'eau ;"));
body.push(Bullet("améliorer l'hygiène ;"));
body.push(Bullet("isoler les animaux concernés lorsque cela est approprié ;"));
body.push(Bullet("contacter un technicien ;"));
body.push(Bullet("contacter un vétérinaire."));
body.push(P("En revanche, le système ne doit à aucun moment :"));
body.push(Bullet("établir automatiquement un diagnostic médical ;"));
body.push(Bullet("prescrire un médicament ;"));
body.push(Bullet("déterminer automatiquement une dose de médicament ;"));
body.push(Bullet("remplacer un vétérinaire."));
body.push(P("Toute recommandation générée automatiquement porte la mention qu'il s'agit d'un signal détecté et non d'un avis médical, jusqu'à ce qu'un professionnel l'ait validée ou corrigée."));

// 17. ASSISTANCE
body.push(H1("17. Assistance professionnelle"));
body.push(P("Un éleveur peut, à partir d'une alerte ou de sa propre initiative, créer une demande d'assistance pour signaler un problème et demander de l'aide. Cette demande est transmise à un technicien ou un vétérinaire disponible."));
body.push(P("Le professionnel sollicité peut :"));
body.push(Bullet("consulter les informations disponibles sur l'exploitation et le lot concerné ;"));
body.push(Bullet("consulter l'historique complet du lot avant de répondre ;"));
body.push(Bullet("répondre à la demande ;"));
body.push(Bullet("orienter l'éleveur, y compris vers un vétérinaire si la situation dépasse son propre champ de compétence."));
body.push(P("Le rôle du technicien dans ce processus est donc central : il est la première ligne d'accompagnement de l'éleveur, avant, si nécessaire, l'intervention d'un vétérinaire pour tout ce qui relève du diagnostic ou du traitement médical."));
body.push(Note("à ce stade, l'attribution des demandes à un professionnel se fait manuellement (pas d'attribution automatique par proximité ou disponibilité) ; le document ne précise pas encore de délai de relance si une demande reste sans réponse — point à discuter avec le technicien."));

// 18. CONTENUS ÉDUCATIFS
body.push(H1("18. Contenus éducatifs"));
body.push(P("L'application propose une bibliothèque de contenus éducatifs, consultable même sans connexion une fois le contenu déjà ouvert une première fois. Ces contenus peuvent porter sur :"));
body.push(Bullet("les bonnes pratiques d'élevage ;"));
body.push(Bullet("l'hygiène ;"));
body.push(Bullet("la biosécurité ;"));
body.push(Bullet("l'alimentation ;"));
body.push(Bullet("la prévention ;"));
body.push(Bullet("le suivi général des volailles."));
body.push(P("Le technicien peut contribuer à :"));
body.push(Bullet("proposer des sujets de contenus utiles pour les éleveurs de la zone ;"));
body.push(Bullet("participer à la validation du contenu sur le plan métier ;"));
body.push(Bullet("identifier les informations prioritaires à transmettre aux éleveurs débutants."));

// 19. FONCTIONNEMENT SANS INTERNET
body.push(H1("19. Fonctionnement sans internet"));
body.push(P("L'application est conçue pour permettre à l'éleveur de continuer à travailler même sans connexion internet, ce qui est important dans de nombreuses zones rurales. Concrètement, l'éleveur peut, même hors connexion :"));
body.push(Bullet("consulter les informations déjà enregistrées sur ses exploitations et lots ;"));
body.push(Bullet("enregistrer un suivi quotidien ;"));
body.push(Bullet("déclarer une mortalité ;"));
body.push(Bullet("enregistrer une observation ;"));
body.push(Bullet("consulter les contenus éducatifs déjà consultés une première fois."));
body.push(P("Les données saisies sans connexion sont conservées sur le téléphone et transmises automatiquement dès que la connexion est disponible à nouveau, sans action supplémentaire de l'éleveur."));

// 20. LIMITES DU SYSTÈME
body.push(H1("20. Limites du système"));
body.push(P("Cette section fixe un cadre clair, à respecter à tout moment dans le projet."));
body.push(P("AvicoleGuard est un outil :"));
body.push(Bullet("d'accompagnement ;"));
body.push(Bullet("de suivi ;"));
body.push(Bullet("d'organisation ;"));
body.push(Bullet("de prévention ;"));
body.push(Bullet("d'alerte ;"));
body.push(Bullet("d'aide à la décision."));
body.push(P("AvicoleGuard n'est pas :"));
body.push(Bullet("un vétérinaire ;"));
body.push(Bullet("un système de diagnostic médical autonome ;"));
body.push(Bullet("un système de prescription médicale."));
body.push(Quote("Le diagnostic et les décisions médicales restent, à tout moment, sous la responsabilité des professionnels compétents."));

// 21. PARTICIPATION ATTENDUE DU TECHNICIEN
body.push(H1("21. Participation attendue du technicien"));
body.push(P("Le technicien est invité à contribuer à la définition des éléments suivants, chacun étant détaillé dans les sections précédentes de ce document :"));
body.push(H3("A. Données d'élevage"));
body.push(Bullet("quelles informations doivent être enregistrées ;"));
body.push(Bullet("quelles informations sont prioritaires ;"));
body.push(Bullet("quelles informations sont inutiles."));
body.push(H3("B. Suivi quotidien"));
body.push(Bullet("quelles données doivent être suivies ;"));
body.push(Bullet("à quelle fréquence ;"));
body.push(Bullet("lesquelles sont réellement faciles à collecter sur le terrain."));
body.push(H3("C. Santé animale"));
body.push(Bullet("les observations à proposer ;"));
body.push(Bullet("les anomalies à surveiller ;"));
body.push(Bullet("les informations importantes à enregistrer."));
body.push(H3("D. Mortalité"));
body.push(Bullet("les informations nécessaires lors d'une déclaration ;"));
body.push(Bullet("les éléments importants pour comprendre une situation."));
body.push(H3("E. Biosécurité"));
body.push(Bullet("les pratiques importantes à intégrer ;"));
body.push(Bullet("les informations utiles à transmettre aux éleveurs."));
body.push(H3("F. Alimentation"));
body.push(Bullet("les informations importantes à suivre ;"));
body.push(Bullet("les indicateurs utiles."));
body.push(H3("G. Production"));
body.push(Bullet("les indicateurs de performance pertinents selon le type d'élevage."));

// 22. QUESTIONS DE CONTRIBUTION
body.push(H1("22. Questions de contribution pour le technicien"));
body.push(P("Cette section permet au technicien de donner directement son avis. Les réponses apportées ici nourriront la synthèse des contributions (section 23)."));

const questions = [
  ["1. Informations sur l'élevage", "Quelles sont, selon vous, les informations indispensables à enregistrer pour un élevage avicole ?"],
  ["2. Suivi quotidien", "Quelles données un éleveur devrait-il enregistrer quotidiennement ?"],
  ["3. Mortalité", "Quelles informations sont importantes lorsqu'un éleveur enregistre une mortalité ?"],
  ["4. Observations sanitaires", "Quels signes ou observations visibles devraient être proposés dans l'application ?"],
  ["5. Santé animale", "Quelles opérations sanitaires devraient être suivies par l'application ?"],
  ["6. Biosécurité", "Quelles pratiques importantes devraient être prises en compte ?"],
  ["7. Alimentation", "Quelles informations concernant l'alimentation sont importantes ?"],
  ["8. Production", "Quels indicateurs doivent être suivis selon le type d'élevage ?"],
  ["9. Alertes", "Quelles situations devraient générer une alerte dans l'application ?"],
  ["10. Fonctionnalités manquantes", "Quelles fonctionnalités importantes liées à l'élevage ou à la santé animale sont absentes ?"],
];

questions.forEach(([title, q]) => {
  body.push(H3(title));
  body.push(P(q, { italics: true }));
  body.push(new Paragraph({
    children: [new TextRun({ text: "Réponse :", bold: true })],
    spacing: { after: 60 },
  }));
  body.push(new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "999999", space: 4 } },
    spacing: { after: 40 },
    children: [new TextRun({ text: " " })],
  }));
  body.push(new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "999999", space: 4 } },
    spacing: { after: 40 },
    children: [new TextRun({ text: " " })],
  }));
  body.push(new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "999999", space: 4 } },
    spacing: { after: 200 },
    children: [new TextRun({ text: " " })],
  }));
});

// 23. SYNTHÈSE
body.push(H1("23. Synthèse des contributions"));
body.push(P("Tableau à compléter à l'issue des échanges avec le technicien, pour garder une trace claire de ce qui doit être intégré au projet."));

const syntheseHeaders = ["Domaine", "Proposition du technicien", "Priorité", "À intégrer ?"];
const syntheseRows = [
  ["Élevage", "", "", ""],
  ["Lots", "", "", ""],
  ["Suivi quotidien", "", "", ""],
  ["Mortalité", "", "", ""],
  ["Santé animale", "", "", ""],
  ["Observations", "", "", ""],
  ["Biosécurité", "", "", ""],
  ["Alimentation", "", "", ""],
  ["Production", "", "", ""],
  ["Alertes", "", "", ""],
];
body.push(makeTable(syntheseHeaders, syntheseRows, [2200, 4200, 1400, 1600]));
body.push(Spacer());

// ANNEXE TECHNIQUE
body.push(PageBreakP());
body.push(H1("Annexe technique (information, non prioritaire)"));
body.push(P("Cette annexe est fournie uniquement à titre informatif. Elle ne relève pas du champ d'expertise attendu du technicien en élevage et santé animale, et ne doit pas être le centre de son attention."));
body.push(Bullet("L'application fonctionne sur téléphone mobile (Android), avec un fonctionnement possible sans connexion internet pour les tâches de terrain."));
body.push(Bullet("Les informations saisies sont conservées de façon sécurisée, avec un accès strictement limité aux données de son propre élevage pour chaque éleveur."));
body.push(Bullet("Les données saisies hors connexion sont automatiquement transmises et mises à jour dès que la connexion redevient disponible, sans risque de doublon."));
body.push(Bullet("Les aspects de développement logiciel, d'architecture technique, de base de données et de sécurité informatique sont gérés par l'équipe de développement du projet et ne nécessitent aucune action de la part du technicien."));

// ---------- BUILD DOCUMENT ----------

const doc = new Document({
  creator: "AvicoleGuard",
  title: "Cahier des charges métier — AvicoleGuard",
  styles: {
    default: {
      document: {
        run: { font: "Calibri", size: 22 },
      },
    },
    paragraphStyles: [
      {
        id: "Heading1",
        name: "Heading 1",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { bold: true, size: 30, color: COLOR_PRIMARY, font: "Calibri" },
        paragraph: { spacing: { before: 400, after: 200 }, border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: COLOR_PRIMARY, space: 4 } } },
      },
      {
        id: "Heading2",
        name: "Heading 2",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { bold: true, size: 26, color: COLOR_ACCENT, font: "Calibri" },
        paragraph: { spacing: { before: 280, after: 140 } },
      },
      {
        id: "Heading3",
        name: "Heading 3",
        basedOn: "Normal",
        next: "Normal",
        quickFormat: true,
        run: { bold: true, italics: true, size: 23, color: "444444", font: "Calibri" },
        paragraph: { spacing: { before: 200, after: 100 } },
      },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 }, // A4
          margin: { top: 1000, bottom: 1000, left: 1100, right: 1100 },
        },
      },
      children: titlePage,
    },
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1000, bottom: 1000, left: 1100, right: 1100 },
        },
      },
      headers: {
        default: new Header({
          children: [new Paragraph({
            alignment: AlignmentType.RIGHT,
            children: [new TextRun({ text: "AvicoleGuard — Cahier des charges métier", size: 16, color: "888888" })],
          })],
        }),
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: "Page ", size: 16, color: "888888" }),
              new TextRun({ children: [PageNumber.CURRENT], size: 16, color: "888888" }),
              new TextRun({ text: " / ", size: 16, color: "888888" }),
              new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 16, color: "888888" }),
            ],
          })],
        }),
      },
      children: body,
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync("/home/claude/avicoleguard/CAHIER_DES_CHARGES_METIER_AVICOLEGUARD.docx", buffer);
  console.log("done");
});