import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../services/todo_manager.dart';

/// Port of the iOS `TodoView`.
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(TodoManager todos) {
    final String title = _input.text.trim();
    if (title.isEmpty) return;
    todos.add(title);
    _input.clear();
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;
    final TodoManager todos = context.watch<TodoManager>();
    final bool canAdd = _input.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _focus.unfocus(),
      child: Container(
        color: DS.bg,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  t.todosTitle,
                  style: DS.headline(17).copyWith(color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _input,
                        focusNode: _focus,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _add(todos),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: DS.accent,
                        decoration: InputDecoration(
                          hintText: t.todoPlaceholder,
                          hintStyle:
                              const TextStyle(color: DS.textTertiary),
                          filled: true,
                          fillColor: DS.surfaceHi,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: canAdd ? () => _add(todos) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: canAdd ? DS.accent : DS.surfaceHi,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t.todoAdd,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                canAdd ? Colors.black : DS.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: todos.todos.isEmpty
                    ? _empty(t)
                    : ListView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        children: <Widget>[
                          if (todos.open.isNotEmpty) ...<Widget>[
                            _header(t.todoOpen),
                            for (final Todo todo in todos.open)
                              _row(todo, todos),
                            const SizedBox(height: 16),
                          ],
                          if (todos.done.isNotEmpty) ...<Widget>[
                            _header(t.todoDone),
                            for (final Todo todo in todos.done)
                              _row(todo, todos),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(Translations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.check_circle_outline,
              size: 56, color: DS.textTertiary),
          const SizedBox(height: 12),
          Text(t.todoEmpty,
              style: DS.display(22).copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              t.todoEmptyDesc,
              textAlign: TextAlign.center,
              style: DS.body(14).copyWith(color: DS.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: DS.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _row(Todo todo, TodoManager todos) {
    return Dismissible(
      key: ValueKey<String>(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: DS.phaseRest,
          borderRadius: BorderRadius.circular(DS.radiusCard),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => todos.deleteIds(<String>[todo.id]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.radiusCard),
          onTap: () => todos.toggle(todo),
          child: DSCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  todo.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: todo.isDone ? DS.accent : DS.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: todo.isDone ? DS.textSecondary : Colors.white,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: DS.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
