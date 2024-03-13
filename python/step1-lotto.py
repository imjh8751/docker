import requests # requests 모듈
from bs4 import BeautifulSoup # BeautifulSoup 모듈
import psycopg2 # postgres db 모듈

# postgres db에 연결하는 함수
def connect_to_database():
    return psycopg2.connect(
        host='itapi.org', # 호스트 주소
        port='15432', # port
        user='postgres', # 사용자 이름
        password='postgres', # 비밀번호
        database='postgres' # 데이터베이스 이름
    )

# 동행복권 사이트에서 당첨번호와 회차를 크롤링하는 함수
def crawl_lotto_numbers():
    lotto_numbers = [] # 당첨번호를 저장할 리스트
    url = "https://dhlottery.co.kr/gameResult.do?method=byWin" # 동행복권 사이트의 당첨번호 페이지 URL
    response = requests.get(url) # GET 요청을 보낸다
    soup = BeautifulSoup(response.text, 'html.parser') # 응답의 HTML을 파싱한다
    numbers = soup.select('.num.win span') # 당첨번호를 담고 있는 span 태그들을 선택한다
    for number in numbers: # 각 span 태그에 대해
        lotto_numbers.append(number.text) # 텍스트를 정수로 변환하고 리스트에 추가한다
    bonus = soup.select_one('.num.bonus span') # 보너스 번호를 담고 있는 span 태그를 선택한다
    lotto_numbers.append(bonus.text) # 텍스트를 정수로 변환하고 리스트에 추가한다
    round = soup.select_one('.win_result strong') # 회차를 담고 있는 strong 태그를 선택한다
    lotto_numbers.append(round.text[:-1]) # 텍스트에서 '회'를 제외하고 정수로 변환하고 리스트에 추가한다
    return lotto_numbers # 당첨번호와 회차를 포함한 리스트를 반환한다

# 당첨번호와 회차를 데이터베이스에 저장하는 함수
def save_to_database(connection, numbers):
    cursor = connection.cursor()
    # tb_lotto_item 테이블에 당첨번호와 회차를 저장하는 쿼리
    query = "INSERT INTO tb_lotto_item (num1, num2, num3, num4, num5, num6, bonus, round) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
    # 중복된 회차가 존재할 경우 입력하지 않도록 ON CONFLICT DO NOTHING 절을 추가한다
    query += " ON CONFLICT (round) DO NOTHING"
    try:
        cursor.execute(query, numbers) # 쿼리를 실행하고 당첨번호와 회차를 튜플로 전달한다
        connection.commit() # 변경사항을 커밋한다
        if cursor.rowcount == 1: # 쿼리가 성공적으로 실행되었다면
            print("DB 입력 성공!") # 성공 메세지 출력
        else: # 쿼리가 실패했다면 (중복된 회차가 존재한다면)
            print("DB 입력 실패! 중복된 데이터:", numbers) # 실패 메세지와 중복된 데이터 출력
    except Exception as e: # 쿼리 실행 중 에러가 발생했다면
        print("DB 입력 에러! 에러 내용:", e) # 에러 메세지와 에러 내용 출력
    finally:
        cursor.close() # 커서를 닫는다

# 동행복권 사이트에서 회차를 크롤링하는 함수
def crawl_lotto_round():
    url = "https://dhlottery.co.kr/gameResult.do?method=byWin" # 동행복권 사이트의 당첨번호 페이지 URL
    response = requests.get(url) # GET 요청을 보낸다
    soup = BeautifulSoup(response.text, 'html.parser') # 응답의 HTML을 파싱한다
    round = soup.select_one('.win_result strong') # 회차를 담고 있는 strong 태그를 선택한다
    return round.text[:-1] # 텍스트에서 '회'를 제외하고 정수로 변환하여 반환한다

# tb_lotto 테이블의 데이터와 당첨번호 비교 및 rank, count 업데이트
def update_lotto_rank_and_count(connection, round_number, winning_numbers, bonus_number):
    cursor = connection.cursor()
    cursor.execute('SELECT idx, round, num1, num2, num3, num4, num5, num6 FROM tb_lotto WHERE round = %s', (round_number,))
    lotto_rows = cursor.fetchall()
    
    # 당첨번호 및 보너스번호를 비교하여 등수와 맞은 개수를 UPDATE
    for row in lotto_rows:
      match_count = len(set(row[2:8]) & set(winning_numbers[0:6])) # 당첨번호 맞춘 개수 추출
      is_bonus_matched = bonus_number in row[2:8] # 보너스 번호 포함여부 확인
      rank = calculate_rank(match_count, is_bonus_matched) # 담청번호 등수 추출
      cursor.execute(
        'UPDATE tb_lotto SET rank = %s, count = %s WHERE idx = %s',
        (rank, match_count, row[0])
      )
    connection.commit()
    cursor.close()

# 순위 계산 함수
def calculate_rank(match_count, is_bonus_matched):
    if match_count == 6:
        return 1
    elif match_count == 5 and is_bonus_matched:
        return 2
    elif match_count == 5:
        return 3
    elif match_count == 4:
        return 4
    elif match_count == 3:
        return 5
    return 0

# 메인 코드
if __name__ == '__main__':
    db_connection = connect_to_database() # postgres db에 연결한다
    lotto_numbers = crawl_lotto_numbers() # 동행복권 사이트에서 당첨번호와 회차를 크롤링한다
    lotto_round = crawl_lotto_round() # 동행복권 사이트에서 회차를 크롤링한다
    #print(lotto_numbers)
    #print(lotto_round)
    update_lotto_rank_and_count(db_connection, lotto_round, lotto_numbers, lotto_numbers[6]) # tb_lotto 테이블의 데이터와 회차를 비교하고, rank와 count 컬럼에 값을 입력한다
    save_to_database(db_connection, lotto_numbers) # 당첨번호와 회차를 데이터베이스에 저장한다
    db_connection.close() # 데이터베이스 연결을 닫는다
