import random # 무작위 모듈
from collections import Counter # 카운터 모듈
from tqdm import tqdm # progress 바 모듈
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

# 로또 번호 6개를 무작위로 생성하는 함수
def generate_lotto_numbers():
    return sorted(random.sample(range(1, 46), 6)) # 1부터 45까지의 숫자 중에서 6개를 뽑아서 정렬한다

# 로또 번호 6개를 시뮬레이션하는 함수
def simulate_lotto(draws):
    simulation_results = [] # 결과를 저장할 리스트
    for _ in tqdm(range(draws)): # draws번 반복하면서 progress 바를 표시한다
        numbers = tuple(generate_lotto_numbers()) # 로또 번호 6개를 생성하고 튜플로 만든다
        simulation_results.append(numbers) # 결과 리스트에 추가한다
    return Counter(simulation_results) # 결과를 카운터 객체로 반환한다

# 가장 적합한 6개 숫자와 회차를 데이터베이스에 저장하는 함수
def save_to_database(connection, results):
    cursor = connection.cursor()
    # tb_lotto_item 테이블에서 마지막 회차를 조회하는 쿼리
    query = "SELECT MAX(round) FROM tb_lotto_item"
    cursor.execute(query) # 쿼리를 실행한다
    last_round = cursor.fetchone()[0] # 결과에서 첫번째 행의 첫번째 열을 가져온다
    if last_round is None: # 결과가 없다면 (테이블이 비어있다면)
        last_round = 0 # 마지막 회차를 0으로 설정한다
    # tb_lotto 테이블에 가장 많이 나온 번호 조합 상위 5개를 데이터베이스에 저장
    for i, (numbers, frequency) in enumerate(results.most_common(10), 1): # 가장 많이 나온 번호 조합 상위 5개를 반복한다
        round = int(last_round) + 1 # 회차는 마지막 회차에서 1씩 증가한다
        cursor.execute(
            'INSERT INTO tb_lotto (round, num1, num2, num3, num4, num5, num6, freq) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)',
            (round, *numbers, frequency) # 회차와 번호들을 튜플로 전달한다
        )
    connection.commit() # 변경사항을 커밋한다
    cursor.close() # 커서를 닫는다

# 가장 적합한 6개 숫자를 5번 출력하는 함수
def print_best_numbers(results):
    message = ""
    for i, (numbers, frequency) in enumerate(results.most_common(10), 1): # 가장 많이 나온 번호 조합 상위 5개를 반복한다
        print(f"{i}번째: {numbers}, 빈도: {frequency}") # 번호와 빈도를 출력한다
        message += f"{i}번째: {numbers}, 빈도: {frequency}\n" # 번호와 빈도를 메시지에 추가한다
    return message

# mattermost, rocket.chat, telegram에 메시지를 전송하는 함수
def send_message_to_platforms(message):
    import requests # requests 모듈
    import telegram # telegram 모듈

    # mattermost에 메시지 전송
    mattermost_webhook_url = "https://mattermost.itapi.org/hooks/1w8qm1s4oi8g9dekwxz6zwdzka" # mattermost webhook URL
    mattermost_payload = {"text": message} # 메시지 내용을 JSON 형식으로 담는다
    requests.post(mattermost_webhook_url, json=mattermost_payload) # POST 요청을 보낸다

    # rocket.chat에 메시지 전송
    rocket_webhook_url = "https://rocketchat.itapi.org/hooks/65eda89cb3e14fc8e09e3ec0/gXELG8hxsd2s3nC2feLbqfdxhxpToyzu6TG69RpbBnfiPA3t" # rocket.chat webhook URL
    rocket_payload = {"text": message} # 메시지 내용을 JSON 형식으로 담는다
    requests.post(rocket_webhook_url, json=rocket_payload) # POST 요청을 보낸다


# 메인 코드
if __name__ == '__main__':
    db_connection = connect_to_database() # postgres db에 연결한다
    results = simulate_lotto(99999999) # 로또 번호 6개를 시뮬레이션 9999999번 한다
    save_to_database(db_connection, results) # 가장 적합한 6개 숫자와 회차를 데이터베이스에 저장한다
    message = print_best_numbers(results) # 가장 적합한 6개 숫자를 5번 출력한다
    send_message_to_platforms(message) # mattermost, rocket.chat, telegram에 메시지를 전송한다
    db_connection.close() # 데이터베이스 연결을 닫는다
