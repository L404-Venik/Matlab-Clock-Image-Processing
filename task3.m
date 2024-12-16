clc
clear
close all

%Clock = imread('clock.png');
%Clock = imread('clock.jpg');
gray_clock = rgb2gray(Clock);

[rows, cols] = size(gray_clock);

% поиск линий преобразованием Хафа
edges = edge(gray_clock, 'Canny');
[H, T, R] = hough(edges);
P = houghpeaks(H, 5);
lines = houghlines(edges, T, R, P, 'MinLength', 0.15 * max(rows,cols));


% агрегация информации о длинах линий и их углах
figure, imshow(Clock), hold on;
center = [cols / 2, rows / 2];
radius = min(rows, cols) / 2;
lines_data = [];
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    % Отображение линий
    plot(xy(:,1), xy(:,2), 'LineWidth', 2); 
    
    % Сохраняем информацию о длинах и углах
    len = norm(lines(k).point1 - lines(k).point2);
    angle = lines(k).theta;

    % Находим точку, которая дальше от центра
    dist1 = norm(lines(k).point1 - center);
    dist2 = norm(lines(k).point2 - center);
    if dist1 > dist2
        farthest_point = lines(k).point1;
    else
        farthest_point = lines(k).point2;
    end
    
    if (farthest_point(2) > (cols * 0.65))
        angle = angle + 180; % еслистрелка в нижней половине циферблата - нужно добавить 180. потому что все углы из диапазона [-90,90]
    end
    % Угол наклона
    angle = mod(angle, 360);

    lines_data = [lines_data; len, angle, k];
end

lines_data = sortrows(lines_data, 1, 'descend'); % Сортируем по длине


% Подавление немаксимумов (выбор самой длинной линии 
% для каждого найденного угла +- angel_tolerance)
suppressed_lines = [];
angle_tolerance = 10; % Допуск в градусах
for i = 1:size(lines_data, 1)
    current_angle = lines_data(i, 2);
    if isempty(suppressed_lines)
        suppressed_lines = lines_data(i, :);
    else
        % Проверяем, есть ли близкий угол в уже выбранных линиях
        angles_in_range = abs(suppressed_lines(:, 2) - current_angle) <= angle_tolerance;
        if ~any(angles_in_range)
            suppressed_lines = [suppressed_lines; lines_data(i, :)];
        end
    end
end

% Если в suppressed_lines меньше 2 значений
if size(suppressed_lines, 1) < 2
    % Добавляем недостающие строки из lines_data
    remaining_lines = setdiff(1:size(lines_data, 1), find(ismember(lines_data, suppressed_lines, 'rows')));
    num_needed = 2 - size(suppressed_lines, 1);
    suppressed_lines = [suppressed_lines; lines_data(remaining_lines(1:num_needed), :)];
end

% Получение углов и перевод во время
minute_angle = suppressed_lines(1, 2);
hour_angle = suppressed_lines(2, 2);
minute = mod(round(minute_angle / 6),60);
hour = mod(floor(hour_angle / 30), 12);


fprintf('На часах %02d:%02d\n', hour, minute);