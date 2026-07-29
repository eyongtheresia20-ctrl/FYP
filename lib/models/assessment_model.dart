class AssessmentQuestion {
  final int id;
  final String questionEn;
  final String questionFr;
  final List<String> optionsEn;
  final List<String> optionsFr;

  const AssessmentQuestion({
    required this.id,
    required this.questionEn,
    required this.questionFr,
    required this.optionsEn,
    required this.optionsFr,
  });
}

class LstQuestions {
  static const List<AssessmentQuestion> list = [
    AssessmentQuestion(
      id: 1,
      questionEn: 'I- To learn a geography, history, or entrepreneurship lesson:',
      questionFr: 'I- Pour apprendre une leçon de géographie, d’histoire ou de l’Éducation à la citoyenneté :',
      optionsEn: [
        '1 - I repeat it loudly or quietly',
        '2 - I view it out in draft form, with emphasis on diagrams, graphs',
        '3 - I walk up and down the yard or around the room',
        '4 - I summarize it and read silently',
      ],
      optionsFr: [
        '1 - Je la répète à voix haute ou à voix basse',
        '2 - Je la consulte sous forme de brouillon, en mettant l\'accent sur les diagrammes et les graphiques',
        '3 - Je marche de long en large dans la cour ou dans la pièce',
        '4 - Je la résume et je la lis en silence',
      ],
    ),
    AssessmentQuestion(
      id: 2,
      questionEn: 'II- To recall a grammatical rule:',
      questionFr: 'II- Pour rappeler une règle de grammaire :',
      optionsEn: [
        '1 - I recall the words spoken by the teacher',
        '2 - I recall the page of my notebook where it is written',
        '3 - I recall what I was doing when I learnt that rule',
        '4 - I re-write the sentence',
      ],
      optionsFr: [
        '1 - Je me souviens des paroles prononcées par le professeur',
        '2 - Je me souviens de la page de mon cahier où elle est écrite',
        '3 - Je me souviens de ce que je faisais quand j\'ai appris cette règle',
        '4 - Je réécris la phrase',
      ],
    ),
    AssessmentQuestion(
      id: 3,
      questionEn: 'III- When I think of my best friend:',
      questionFr: 'III- Quand je pense à mon meilleur ami :',
      optionsEn: [
        '1 - The first thing I remember is the sound of his voice',
        '2 - The first thing I remember is his face, picture, appearance',
        '3 - I recall his demonstrations in class',
        '4 - The first thing that I remember is his quality of expression',
      ],
      optionsFr: [
        '1 - La première chose dont je me souviens c\'est le son de sa voix',
        '2 - La première chose dont je me souviens c\'est son visage, sa photo, son apparence',
        '3 - Je me souviens de ses démonstrations en classe',
        '4 - La première chose dont je me souviens c\'est sa qualité d\'expression',
      ],
    ),
    AssessmentQuestion(
      id: 4,
      questionEn: 'IV- In order to have an idea about a chapter or lesson:',
      questionFr: 'IV- Pour avoir une idée sur un chapitre ou une leçon :',
      optionsEn: [
        '1 - I first read the text, listen to an audio or follow a discussion about the text',
        '2 - I first look at the diagrams, photos or graphs',
        '3 - I wet my fingers to turn the pages',
        '4 - I first of all, read and jot down the essential information',
      ],
      optionsFr: [
        '1 - J\'écoute un audio ou je suis une discussion sur le texte',
        '2 - Je regarde d\'abord les schémas, photos ou graphiques',
        '3 - Je mouille mes doigts pour tourner les pages',
        '4 - Tout d\'abord, je lis et note les informations essentielles',
      ],
    ),
    AssessmentQuestion(
      id: 5,
      questionEn: 'V- When I am looking for a page from the table of contents:',
      questionFr: 'V- Lorsque je recherche une page dans la table des matières :',
      optionsEn: [
        '1 - I repeat the page number in my mind or with a low voice',
        '2 - I look at the page number without memorizing it',
        '3 - I wet my fingers to turn the pages',
        '4 - I note the page number mentally or in writing',
      ],
      optionsFr: [
        '1 - Je répète le numéro de page dans ma tête ou à voix basse',
        '2 - Je regarde le numéro de page sans le mémoriser',
        '3 - Je mouille mes doigts pour tourner les pages',
        '4 - Je note le numéro de page mentalement ou par écrit',
      ],
    ),
    AssessmentQuestion(
      id: 6,
      questionEn: 'VI- My hobby is:',
      questionFr: 'VI- Mon passe-temps préféré c\'est :',
      optionsEn: [
        '1 - Listening to music or an entertaining discussion',
        '2 - Cinema or watching videos',
        '3 - Doing sports or drama',
        '4 - Reading, writing or both',
      ],
      optionsFr: [
        '1 - Écouter de la musique ou une discussion divertissante',
        '2 - Aller au cinéma ou regarder des vidéos',
        '3 - Faire du sport ou du théâtre',
        '4 - Lire, écrire ou les deux',
      ],
    ),
    AssessmentQuestion(
      id: 7,
      questionEn: 'VII- I understand better when:',
      questionFr: 'VII- Je comprends mieux quand :',
      optionsEn: [
        '1 - Someone speaks and I listen',
        '2 - Reading my notes with emphasis on pictures and videos about the lesson',
        '3 - I recall an interesting scene or sketch about the lesson',
        '4 - Read carefully and summarize',
      ],
      optionsFr: [
        '1 - Quelqu\'un parle et j\'écoute',
        '2 - Je lis mes notes en mettant l\'accent sur les images et les vidéos concernant la leçon',
        '3 - Je me souviens d\'une scène ou d\'un croquis intéressant de la leçon',
        '4 - Je fais une lecture attentive puis un résumé',
      ],
    ),
    AssessmentQuestion(
      id: 8,
      questionEn: 'VIII- To find an explanation:',
      questionFr: 'VIII- Pour trouver une explication :',
      optionsEn: [
        '1 - I recall what the teacher said in class',
        '2 - I refer to the written explanations on the board or in my notebook or pictures, graphs, tables, video etc',
        '3 - I recall a scene or sketch about the lesson',
        '4 - I jot down my ideas and organize them',
      ],
      optionsFr: [
        '1 - Je me souviens de ce que le professeur a dit en classe',
        '2 - Je me réfère aux explications écrites au tableau ou dans mon cahier ou à des images, graphiques, tableaux, vidéos etc',
        '3 - Je me souviens d\'une scène ou d\'un croquis de la leçon',
        '4 - Je note mes idées et les organise',
      ],
    ),
    AssessmentQuestion(
      id: 9,
      questionEn: 'IX- I learn best:',
      questionFr: 'IX- J\'apprends mieux :',
      optionsEn: [
        '1 - When I listen to the teacher',
        '2 - By highlighting essential ideas in my notes with emphasis on pictures, graphs and videos',
        '3 - If the noise around me is rhythmic and low',
        '4 - By re-writing and re-reading essential ideas',
      ],
      optionsFr: [
        '1 - Quand j\'écoute le professeur',
        '2 - En mettant en évidence les idées essentielles dans mes notes et en mettant l\'accent sur les images, les graphiques et les vidéos',
        '3 - Lorsque le bruit autour de moi est rythmé et faible',
        '4 - En réécrivant et en relisant les idées essentielles',
      ],
    ),
    AssessmentQuestion(
      id: 10,
      questionEn: 'X- I understand my teacher better:',
      questionFr: 'X- Je comprends mieux mon professeur quand :',
      optionsEn: [
        '1 - When I listen to his lesson',
        '2 - By reading my notes with emphasis on diagrams, pictures, graphs and videos',
        '3 - If I recall an interesting scene or sketch about the lesson',
        '4 - By reading carefully, re-writing and summarizing',
      ],
      optionsFr: [
        '1 - J\'écoute son enseignement',
        '2 - Lors de la lecture de mes notes en insistant sur les diagrammes, les images, les graphiques et les vidéos',
        '3 - Si je me souviens d\'une scène ou d\'un croquis intéressant de la leçon',
        '4 - Je lis attentivement, réécris et résume ses enseignements',
      ],
    ),
  ];
}
