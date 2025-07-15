require 'sinatra'

set :environment, :production

get '/' do
  today = Time.now
  y = today.year
  m = today.month
  redirect "http://127.0.0.1:4567/#{y}/#{m}"
end

get '/:y/:m' do
  @year = params[:y].to_i
  @month = params[:m].to_i

  if @month < 1 || @month > 12 || @year <= 0 then 
    @year = Time.now.year
    @month = Time.now.month
  end

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

  @t = "<table border>"
  @t = @t + "<tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th>"
  @t = @t + "<th>Thu</th><th>Fri</th><th>Sat</th></tr>"

  l = getLastDay(@year, @month)
  h = zeller(@year, @month, 1)

  d = 1
  6.times do |p|
    @t = @t + "<tr>"
    7.times do |q|
      if p == 0 && q < h
        @t = @t + "<td></td>"
      else
        if d <= l
          if(@year == Time.now.year && @month == Time.now.month && d == Time.now.day) # Today
            @t = @t + "<td align=\"right\"><font color=\"green\">#{d}</font></td>"
          elsif (h + d ) % 7 == 0 # Saturday
            @t = @t + "<td align=\"right\"><font color=\"blue\">#{d}</font></td>"
          elsif (h + d ) % 7 == 1 # Sunday
            @t = @t + "<td align=\"right\"><font color=\"red\">#{d}</font></td>"
          else
            @t = @t + "<td align=\"right\">#{d}</td>"
          end
          d += 1
        else
          @t = @t + "<td></td>"
        end
      end
    end
    @t = @t + "</tr>"
    if d > l
      break
    end
  end

  @t = @t + "</table>"

  erb :moncal
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