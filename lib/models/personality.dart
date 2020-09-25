class Personality {
  final PersonalityType personalityType;
  const Personality({this.personalityType});
}

class PersonalityType {
  final Agreeableness agreeableness;
  final Conscientiousness conscientiousness;
  final Openness openness;
  final IntroversionToExtraversion introversionToExtraversion;
  final EmotionalRange emotionalRange;
  const PersonalityType({
    this.agreeableness,
    this.conscientiousness,
    this.openness,
    this.introversionToExtraversion,
    this.emotionalRange,
  });

  factory PersonalityType.fromJson(
    Map<String, dynamic> personality,
  ) {
    return PersonalityType(
      openness: Openness(
        value: personality['personality'][0]['percentile'],
        adventurousness: personality['personality'][0]['children'][0]
            ['percentile'],
        artisticInterests: personality['personality'][0]['children'][1]
            ['percentile'],
        emotionality: personality['personality'][0]['children'][2]
            ['percentile'],
        imagination: personality['personality'][0]['children'][3]['percentile'],
        intellect: personality['personality'][0]['children'][4]['percentile'],
        authorityChallenging: personality['personality'][0]['children'][5]
            ['percentile'],
      ),
      conscientiousness: Conscientiousness(
        value: personality['personality'][1]['percentile'],
        achievementStriving: personality['personality'][1]['children'][0]
            ['percentile'],
        cautiousness: personality['personality'][1]['children'][1]
            ['percentile'],
        dutifulness: personality['personality'][1]['children'][2]['percentile'],
        orderliness: personality['personality'][1]['children'][3]['percentile'],
        selfDiscipline: personality['personality'][1]['children'][4]
            ['percentile'],
        selfEfficacy: personality['personality'][1]['children'][5]
            ['percentile'],
      ),
      introversionToExtraversion: IntroversionToExtraversion(
        value: personality['personality'][2]['percentile'],
        activityLevel: personality['personality'][2]['children'][0]
            ['percentile'],
        assertiveness: personality['personality'][2]['children'][1]
            ['percentile'],
        cheerfulness: personality['personality'][2]['children'][2]
            ['percentile'],
        excitementSeeking: personality['personality'][2]['children'][3]
            ['percentile'],
        outgoing: personality['personality'][2]['children'][4]['percentile'],
        gregariousness: personality['personality'][2]['children'][5]
            ['percentile'],
      ),
      agreeableness: Agreeableness(
        value: personality['personality'][3]['percentile'],
        altruism: personality['personality'][3]['children'][0]['percentile'],
        cooperation: personality['personality'][3]['children'][1]['percentile'],
        modesty: personality['personality'][3]['children'][2]['percentile'],
        uncompromising: personality['personality'][3]['children'][3]
            ['percentile'],
        sympathy: personality['personality'][3]['children'][4]['percentile'],
        trust: personality['personality'][3]['children'][5]['percentile'],
      ),
      emotionalRange: EmotionalRange(
        value: personality['personality'][4]['percentile'],
        fiery: personality['personality'][4]['children'][0]['percentile'],
        proneToWorry: personality['personality'][4]['children'][1]
            ['percentile'],
        melancholy: personality['personality'][4]['children'][2]['percentile'],
        immoderation: personality['personality'][4]['children'][3]
            ['percentile'],
        selfConsciousness: personality['personality'][4]['children'][4]
            ['percentile'],
        susceptibleToStress: personality['personality'][4]['children'][5]
            ['percentile'],
      ),
    );
  }
}

class Agreeableness {
  final value;
  final double altruism;
  final double sympathy;
  final double uncompromising;
  final double trust;
  final double cooperation;
  final double modesty;
  const Agreeableness({
    this.value,
    this.altruism,
    this.sympathy,
    this.uncompromising,
    this.trust,
    this.cooperation,
    this.modesty,
  });
}

class Conscientiousness {
  final double value;
  final double achievementStriving;
  final double dutifulness;
  final double selfDiscipline;
  final double cautiousness;
  final double selfEfficacy;
  final double orderliness;
  const Conscientiousness({
    this.value,
    this.achievementStriving,
    this.dutifulness,
    this.selfDiscipline,
    this.cautiousness,
    this.selfEfficacy,
    this.orderliness,
  });
}

class Openness {
  final double value;
  final double emotionality;
  final double artisticInterests;
  final double adventurousness;
  final double intellect;
  final double imagination;
  final double authorityChallenging;
  const Openness({
    this.value,
    this.emotionality,
    this.artisticInterests,
    this.adventurousness,
    this.intellect,
    this.imagination,
    this.authorityChallenging,
  });
}

class IntroversionToExtraversion {
  final double value;
  final double outgoing;
  final double cheerfulness;
  final double activityLevel;
  final double assertiveness;
  final double gregariousness;
  final double excitementSeeking;
  const IntroversionToExtraversion({
    this.value,
    this.outgoing,
    this.cheerfulness,
    this.activityLevel,
    this.assertiveness,
    this.gregariousness,
    this.excitementSeeking,
  });
}

class EmotionalRange {
  final double value;
  final double proneToWorry;
  final double susceptibleToStress;
  final double selfConsciousness;
  final double immoderation;
  final double fiery;
  final double melancholy;
  const EmotionalRange({
    this.value,
    this.proneToWorry,
    this.susceptibleToStress,
    this.selfConsciousness,
    this.immoderation,
    this.fiery,
    this.melancholy,
  });
}
