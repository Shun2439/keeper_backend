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
    @h += "<td>#{a.date}</td>"
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
          anniversaries_on_day = @anniversaries.select { |a| a.date.end_with?("#{'%02d' % @month}#{'%02d' % d}") || (a.date.end_with?("#{'%02d' % @month}  ") && a.week_of_month == (d / 7) && a.day_of_week == (d % 7 + 1)) }
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
  b = Anniversaries.new
  b.id = params[:id]
  b.date = params[:date]
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