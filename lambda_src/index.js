// lambda_src/index.js

exports.handler = async (event) => {
    // SQS로부터 들어온 이벤트 메시지들을 순회하며 처리
    for (const record of event.Records) {
        const payload = JSON.parse(record.body);
        
        console.log(`[이벤트 수신] 메시지 ID: ${record.messageId}`);
        console.log(`[이벤트 유형]: ${payload.event_type || 'DEFAULT'}`);
        console.log(`[상세 데이터]:`, payload.data || {});
        
        // 정석적인 비동기 작업 분기 처리 예시
        if (payload.event_type === "CREATE_USER") {
            console.log("👤 [회원가입] 환영 이메일 발송 파이프라인 가동");
        } else if (payload.event_type === "ORDER_PLACED") {
            console.log("💳 [주문완료] 결제 완료 및 배송 지시서 발행");
        }
    }
    
    return { statusCode: 200, body: "Events processed successfully" };
};