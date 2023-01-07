import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:faker/faker.dart';
import 'package:livinginquiryapp/models/worksheet.dart';
import 'package:basic_utils/basic_utils.dart' as basic_utils;
import 'package:flutter/material.dart';
import 'package:livinginquiryapp/providers/worksheets_provider.dart';

import 'constants.dart';

enum DevOptions { clearData, loadTestData, exportJson }

const Set<String> Tags = {
  "psychology",
  "love",
  "mentalhealth",
  "therapy",
  "health",
  "motivation",
  "wellness",
  "depression",
  "anxiety",
  "life",
  "inspiration",
  "healing",
  "meditation",
  "mindfulness",
  "mentalhealthawareness",
  "art",
  "philosophy",
  "fitness",
  "psychotherapy",
  "selflove",
  "growth",
  "goals",
  "peace",
  "selfcare",
  "mentalillness",
  "recovery",
  "yoga",
  "psychologist",
  "nature",
  "author",
  "emotions",
  "stress",
  "psicoterapia",
  "mentalhealthmatters",
  "trauma",
  "psy",
  "therapist",
  "counseling",
  "quotes",
  "bhfyp",
  "loveyourself",
  "positivevibes",
  "quoteoftheday",
  "mindset",
  "positivity",
  "education",
  "facts",
  "wisdom",
  "healthylifestyle",
  "healthy",
  "lifestyle",
  "beauty",
  "nutrition",
  "healthyliving",
  "wellbeing",
  "workout",
  "skincare",
  "gym",
  "relax",
  "fitnessmotivation",
  "weightloss",
  "spa",
  "fit",
  "instagood"
};
final _faker = new Faker();
final _random = new Random();

/// Generates a positive random integer uniformly distributed on the range
/// from [min], inclusive, to [max], exclusive.
int next(int min, int max) => min + _random.nextInt(max - min);

bool choice(double pct) {
  return _random.nextDouble() <= pct;
}

Worksheet createWorksheet(WorksheetContent content, int ageDays, {Set<String>? tags, int parentId = -1}) {
  final now = DateUtils.dateOnly(DateTime.now());
  final dateCreated = now.subtract(Duration(days: ageDays, hours: next(0, 12)));
  final dateLastEdited = now.subtract(Duration(days: ageDays));
  final starred = choice(0.15);
  final archived = choice(0.08);
  final color = WORKSHEET_COLORS[next(0, WORKSHEET_COLORS.length)];

  content.questions.forEach((q) {
    switch (q.type) {
      case QuestionType.freeform:
        q.answer = _faker.lorem.sentence();
        break;
      case QuestionType.multiple:
        q.answer = q.values?[next(0, q.values!.length)] ?? "";
        break;
    }
  });
  return Worksheet("", content, dateCreated, dateLastEdited, color,
      isArchived: archived, isStarred: starred, parentId: parentId, tags: tags);
}

Future<List<Worksheet>> generateWorksheets(WorksheetRepository repo, int count, List<WorksheetContent> contents,
    {int maxAgeDays = 100}) async {
  final newWorksheets = List.generate(count, (_) {
    final tags = Tags.sample(next(0, 10)).toSet();
    final content = contents[next(0, contents.length)];
    final age = next(0, maxAgeDays);
    return createWorksheet(content.clone(), age, tags: tags);
  });
  newWorksheets.sortBy((ws) => ws.dateCreated);
  int lastParentId = -1;
  for (var ws in newWorksheets) {
    if (ws.content.type == WorksheetType.judgeYourNeighbor) {
      final res = await repo.addWorksheet(ws);
      if (res <= 0) {
        print("Couldn't create worksheet!");
      } else {
        if (choice(0.3)) {
          lastParentId = res;
        }
        ws.id = res;
      }
    } else {
      ws.parentId = choice(0.2) ? lastParentId : -1;
      final res = await repo.addWorksheet(ws);
      if (res <= 0) {
        print("Couldn't create worksheet!");
      } else {
        ws.id = res;
      }
    }
  }
  return newWorksheets;
}
