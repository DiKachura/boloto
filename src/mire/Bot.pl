% Включение отладки для mirebot.
:- debug(mirebot).

% Использование модуля socket из библиотеки Prolog.
:- use_module(library(socket)).

% Определение exit/1 как динамического предиката.
:- dynamic exit/1.

% Определение пути как динамического предиката.
:- dynamic path/1.

% Парсеры для различных направлений.
e(north) --> [north].
e(south) --> [south].
e(west) --> [west].
e(east) --> [east].

% Парсер для списка направлений (выходов).
exits([Exit]) --> e(Exit).
exits([Exit|Exits]) --> e(Exit), exits(Exits).

% Полный парсер для строки с выходами.
parse_exits(Exits) --> [exits], exits(Exits).

% Предикат для разбора токенов, содержащих информацию о выходах.
parse(Tokens) :- phrase(parse_exits(Exits), Tokens, Rest), retractall(exit(_)), assert(exit(Exits)).
parse(_).

% Фильтрация входного списка кодов, удаляются определенные символы и происходит приведение к нижнему регистру.
filter_codes([], []).
filter_codes([H|T1], T2) :-
  char_code(C, H),
  member(C, ['(', ')', ':']),
  filter_codes(T1, T2).
filter_codes([H|T1], [F|T2]) :-
  code_type(F, to_lower(H)),
  filter_codes(T1, T2).

% Инициализация пути.
% :- retractall(path(_)), assert(path([north, north, west, north, south, west, west, north, north])).
:- retractall(path(_)), assert(path([north, east, south, south, west, north|_])).

% Обработка потока данных: считывание направления, формирование команды и отправка ее обратно в поток.
process(Stream) :-
  path([Direction|Rest]),
  format(atom(Command), 'move ~w~n', [Direction]),
  write(Command),
  write(Stream, Command),
  flush_output(Stream),
  retractall(path(_)),
  (Rest == [] -> write(Stream, 'grab keys\n'), flush_output(Stream); assert(path(Rest))).
process(_).

% Отправка приветственного сообщения в поток при подключении.
hello(Stream) :-
  writeln(Stream, 'bot'),
  flush_output(Stream).

% Запуск основного цикла обработки.
run(Stream) :-
  hello(Stream),
  loop(Stream).

% Основной цикл обработки: чтение из потока, обработка входных данных, отправка команды в поток.
loop(Stream) :-
  read_line_to_codes(Stream, Codes),
  filter_codes(Codes, Filtered),
  atom_codes(Atom, Filtered),
  tokenize_atom(Atom, Tokens),
  write(Tokens),
  parse(Tokens),
  nl,
  flush(),
  sleep(1),
  process(Stream),
  loop(Stream).

% Основной предикат, который устанавливает соединение, запускает обработку и затем закрывает соединение.
main :-
  setup_call_cleanup(
    tcp_connect(localhost:3332, Stream, []),
    run(Stream),
    close(Stream)).