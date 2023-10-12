% Включение отладки для mirebot.
:- debug(mirebot).

% Использование модуля socket из библиотеки Prolog.
:- use_module(library(socket)).

% Определение парсеров для различных направлений.
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
parse(Tokens) :- phrase(parse_exits(Exits), Tokens, _), process(Exits).
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

% Обработка потока данных: считывание направления, формирование команды и отправка ее обратно в поток.
process(Exits) :-
  random_member(Direction, Exits),
  format(atom(Command), 'move ~w~n', [Direction]),
  write(Command),
  write(Stream, Command),
  flush_output(Stream).

% Отправка приветственного сообщения в поток при подключении.
hello(Stream) :-
  writeln(Stream, 'Когда приходит время нанести удар, император наносит удар без колебаний. Если вы попадетесь, смерть будет вашим приговором'),
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
  flush_output,
  sleep(1),
  loop(Stream).

% Основной предикат, который устанавливает соединение, запускает обработку и затем закрывает соединение.
main :-
  setup_call_cleanup(
    tcp_connect(localhost:3333, Stream, []),
    run(Stream),
    close(Stream)).