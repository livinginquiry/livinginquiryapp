import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../locator.dart';
import '../models/note.dart';
import '../services/db_provider.dart';

class NotesBloc extends ChangeNotifier {
  DbProvider _db = locator<DbProvider>();
  // Create a broadcast controller that allows this stream to be listened
  // to multiple times. This is the primary, if not only, type of stream you'll be using.
  final _notesControllerDone = StreamController<List<Worksheet>>.broadcast();
  final _notesControllerStarted = StreamController<List<Worksheet>>.broadcast();

  // Input stream. We add our notes to the stream using this variable.
  StreamSink<List<Worksheet>> get _inNotesDone => _notesControllerDone.sink;
  StreamSink<List<Worksheet>> get _inNotesStarted => _notesControllerStarted.sink;

  // Output stream. This one will be used within our pages to display the notes.
  Stream<List<Worksheet>> get notesDone => _notesControllerDone.stream;
  Stream<List<Worksheet>> get notesStarted => _notesControllerStarted.stream;

  // Input stream for adding new notes. We'll call this from our pages.
  final _addNoteController = StreamController<Worksheet>.broadcast();
  StreamSink<Worksheet> get inAddNote => _addNoteController.sink;

  final _saveNoteController = StreamController<Worksheet>.broadcast();
  StreamSink<Worksheet> get inSaveNote => _saveNoteController.sink;

  final _deleteNoteController = StreamController<int>.broadcast();
  StreamSink<int> get inDeleteNote => _deleteNoteController.sink;

  // This bool StreamController will be used to ensure we don't do anything
  // else until a note is actually deleted from the database.
  final _noteDeletedController = StreamController<bool>.broadcast();
  StreamSink<bool> get _inDeleted => _noteDeletedController.sink;
  Stream<bool> get deleted => _noteDeletedController.stream;

  final _noteAddedController = StreamController<int>.broadcast();
  StreamSink<int> get _inAdded => _noteAddedController.sink;
  Stream<int> get added => _noteAddedController.stream;

  Map<String, WorksheetContent> _worksheets;

  NotesBloc() {
    _loadInquiryTypes();

    // Listens for changes to the addNoteController and calls _handleAddNote on change
    _addNoteController.stream.listen(_handleAddNote);
    _saveNoteController.stream.listen(_handleAddNote);
    _deleteNoteController.stream.listen(_handleDeleteNote);
  }

  Future<Map<String, WorksheetContent>> getWorksheets() {
    return _loadInquiryTypes();
  }

  // All stream controllers you create should be closed within this function
  void dispose() {
    _notesControllerDone.close();
    _notesControllerStarted.close();
    _addNoteController.close();
    _saveNoteController.close();
    _deleteNoteController.close();
    _noteDeletedController.close();
    _noteAddedController.close();
  }

  Future<Map<String, WorksheetContent>> _loadInquiryTypes() async {
    if (_worksheets != null) {
      return _worksheets;
    }
    var doc = loadYaml(await rootBundle.loadString('assets/question_types.yaml')) as Map;
    _worksheets = Map.unmodifiable(doc.map((k, v) => MapEntry(k.toString(), WorksheetContent.fromYamlMap(k, v))));

    print(doc);

    print("my worksheets is ${_worksheets.length}");

    return _worksheets;
  }

  void loadWorksheets() async {
    try {
      // Retrieve all the notes from the database
      List<Worksheet> notes = await _db.getWorksheets();

      // Add all of the notes to the stream so we can grab them later from our pages
      _inNotesDone.add(notes.where((item) => item.isComplete).toList());
      _inNotesStarted.add(notes.where((item) => !item.isComplete).toList());
    } catch (e, stacktrace) {
      print("Couldn't load worksheets! $e $stacktrace");
    }
  }

  Future<List<Worksheet>> exportWorksheets() async {
    try {
      return await _db.getWorksheets();
    } catch (e) {
      print("Couldn't load worksheets for export! $e");
    }
    return null;
  }

  void _handleAddNote(Worksheet note) async {
    // Create the note in the database
    int id = await _db.addNote(note);

    _inAdded.add(id);
    // Retrieve all the notes again after one is added.
    // This allows our pages to update properly and display the
    // newly added note.
    loadWorksheets();
  }

  void _handleDeleteNote(int id) async {
    await _db.deleteNote(id);

    // Set this to true in order to ensure a note is deleted
    // before doing anything else
    _inDeleted.add(true);
    loadWorksheets();
  }
}
