# coding: utf-8

require 'sinatra'
require 'active_record'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Anniversaries < ActiveRecord::Base
  self.table_name = 'anniversaries'
end

get '/kanri' do
  @anniversaries = Anniversaries.all

  # Create table
  @h = ""
  @anniversaries.each do |a|
    @h += "<tr>"
    @h += "<td>#{a.id}</td>"
    @h += "<td style=\"white-space: pre-wrap;\">#{a.date}</td>"
    @h += "<td>#{a.week_of_month}</td>"
    @h += "<td>#{a.day_of_week}</td>"
    @h += "<td>#{a.name}</td>"
    @h += "<td>#{a.description}</td>"

    @h += "<form method=\"post\" action=\"/del\">"
    @h += "<td><input type=\"submit\" value=\"Delete\" /></td>"
    @h += "<input type=\"hidden\" name=\"id\" value=\"#{a.id}\" />"
    @h += "<input type=\"hidden\" name=\"_method\" value=\"delete\" />"
    @h += "</form>"

    @h += "</tr>\n"
  end

  erb :kanri
end

get '/' do
  today = Time.now
  y = today.year
  m = today.month
  redirect "http://127.0.0.1:4567/#{y}/#{m}"
end

get '/:y/:m' do
  @anniversaries = Anniversaries.all

  @year = params[:y].to_i
  @month = params[:m].to_i

  # Check year and month
  if @month < 1 || @month > 12 || @year <= 0 then
    @year = Time.now.year
    @month = Time.now.month
  end

  # Previous and next month
  @y1 = @year
  @m1 = @month - 1
  if @m1 == 0
    @m1 = 12
    @y1 -= 1
  end

  @y2 = @year
  @m2 = @month + 1
  if @m2 == 13
    @m2 = 1
    @y2 += 1
  end

  # Create calendar table
  @t = "<table border>"
  @t += "<tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th>"
  @t += "<th>Thu</th><th>Fri</th><th>Sat</th></tr>"

  l = getLastDay(@year, @month)
  h = zeller(@year, @month, 1)

  make_monday_red = false

  d = 1
  6.times do |p|
    @t += "<tr>"
    7.times do |q|
      if p == 0 && q < h
        @t += "<td></td>"
      else
        if d <= l
          # search anniversary from database
          anniversaries_on_day = @anniversaries.select do |a|
            if a.week_of_month.nil? || a.day_of_week.nil?
              a.date.end_with?("#{'%02d' % @month}#{'%02d' % d}")
            else
              a.date[4..5].to_i == @month && a.week_of_month == (d/7) && a.day_of_week == (d % 7 + 1)
            end
          end

          if anniversaries_on_day.any? # anniversary day
            # Sunday check
            if (h + d) % 7 == 1
              make_monday_red = true
            end
            # Create a pop-up for anniversaries
            @t += "<td align=\"right\"><span style=\"position: relative;\"><font color=\"whiteblue\">#{d}</font>"
            @t += "<div style=\"position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%); visibility: hidden; background-color: white; border: 1px solid black; padding: 5px; z-index: 1;\">"
            anniversaries_on_day.each do |a|
              @t += "#{a.name}: #{a.description}<br>"
            end
            @t += "</div></span>"
            @t += "<script>document.currentScript.previousSibling.addEventListener('mouseover', function() { this.querySelector('div').style.visibility = 'visible'; }); document.currentScript.previousSibling.addEventListener('mouseout', function() { this.querySelector('div').style.visibility = 'hidden'; });</script>" # Create a pop-up on mouse over
          elsif(@year == Time.now.year && @month == Time.now.month && d == Time.now.day) # Today
            @t += "<td align=\"right\"><font color=\"whitegreen\">#{d}</font>"
          elsif (h + d ) % 7 == 0 # Saturday
            @t += "<td align=\"right\"><font color=\"blue\">#{d}</font>"
          elsif (h + d ) % 7 == 1 # Sunday
            @t += "<td align=\"right\"><font color=\"red\">#{d}</font>"
          elsif make_monday_red && (h + d) % 7 == 2 # Monday
            make_monday_red = false
            @t += "<td align=\"right\"><font color=\"red\">#{d}</font>"
          else
            @t += "<td align=\"right\">#{d}"
          end

          d += 1
        else
          @t += "<td></td>"
        end
      end
    end
    @t += "</tr>"

    if d > l
      break
    end
  end

  @t += "</table>"

  erb :moncal
end

post '/new' do

  # 1. id check
  # プライマリーキーのIDを指定しない場合は最大値+1を設定
  if params[:id].nil? || can_convert_to_integer_with_exception(params[:id]) != true
    params[:id] = Anniversaries.maximum(:id).to_i + 1
  end

  # 2. 数値のチェック
  if check_month(params[:date][4..5].to_i) && params[:week_of_month].empty? == false && params[:day_of_week].empty? == false
  elsif check_format(params[:date])
  else
    return "入力が不正です。固定月日はYYYYMMDDの形式で、固定曜日はYYYYMMDDかつWeek of monthに週番号、Day of weekに曜日番号を入れてください。"
  end

  # 文字列から除外
  if params[:name].match?(/[<>"']/) || params[:description].match?(/[<>"']/)
    return "不正な文字がふくまれています。"
  end

  b = Anniversaries.new
  b.id = params[:id]
  b.date = params[:date]
  b.week_of_month = params[:week_of_month]
  b.day_of_week = params[:day_of_week]
  b.name = params[:name]
  b.description = params[:description]
  b.save

  redirect "/#{params[:year]}/#{params[:month]}"
end

delete '/del' do
  b = Anniversaries.find(params[:id])
  b.destroy

  redirect "/#{params[:year]}/#{params[:month]}"
end

def isLeapYear(y)
  return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? false : true
end

def getLastDay(y, m)
  return isLeapYear(y) ?
    case m
      when 2
        28
      when 4, 6, 9, 11
        30
    else
      31
    end
  :
    case m
      when 2, 4, 6, 9, 11
        30
      else
        31
    end
end

def zeller(y, m, d)
  case m
    when 1
      m = 13
      y -= 1
    when 2
      m = 14
      y -= 1
  end
  return (y + (y/4).floor - (y/100).floor + (y/400).floor + ((13 * m + 8)/5).floor + d) % 7
end

def can_convert_to_integer_with_exception(str)
  begin
    Integer(str)
    true
  rescue ArgumentError
    false
  end
end

def check_date(s)
  year = s[0..3].to_i
  month = s[4..5].to_i
  day = s[6..7].to_i

  # puts year month day
  return false if year <= 0 || month < 1 || month > 12 || day < 1 || day > getLastDay(year, month)

  # check leap year
  if month == 2 && day == 29 && !isLeapYear(year)
    return false
  end

  return true
end

# 月が正しいか判定
def check_month(month)
  if month < 1 || month > 12
    return false
  end

  true
end

# get normal string
def check_format(s)
  # 文字列の長さと不正文字のチェック
  if s.length != 8 || can_convert_to_integer_with_exception(s) == false
    return false
  end

  # 指定があっているか確認
  if check_date(s) == false
    return false
  end

  return true
end
