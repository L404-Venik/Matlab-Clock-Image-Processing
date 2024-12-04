clc
clear
close all

Clock = imread('clock.png');
%Clock = imread('clock.jpg');
gray_clock = rgb2gray(Clock);


% поиск линий преобразованием Хафа
edges = edge(gray_clock, 'Canny');
[H, T, R] = hough(edges);
P = houghpeaks(H, 5);
lines = houghlines(edges, T, R, P, 'MinLength', 170);

% агрегация информации о длинах линий и их углах
%figure, imshow(Clock), hold on;
lines_data = [];
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    % Отображение линий
    %plot(xy(:,1), xy(:,2), 'LineWidth', 2); 

    % Сохраняем информацию о длинах и углах
    len = norm(lines(k).point1 - lines(k).point2);
    angle = lines(k).theta; %atan2d(diff(xy(:,2)), diff(xy(:,1))); % Угол наклона
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


% Получение углов и перевод во время
minute_angle = mod(suppressed_lines(1, 2), 360);
hour_angle = mod(suppressed_lines(2, 2), 360);
minute = round(minute_angle / 6);
hour = mod(floor(hour_angle / 30), 12);


fprintf('На часах %02d:%02d\n', hour, minute);