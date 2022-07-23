DECLARE 
	CURSOR c_new_transactions IS
		SELECT transaction_no, transaction_date, description, transaction_type, account_no, transaction_amount 
		FROM new_transactions 
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;

    v_transaction_no transaction_detail.transaction_no%TYPE; 
	v_transaction_date transaction_history.transaction_date%TYPE; 
	v_description transaction_history.description%TYPE; 
	v_transaction_type transaction_detail.transaction_type%TYPE; 
	v_account_no transaction_detail.account_no%TYPE; 
	v_transaction_amount transaction_detail.transaction_amount%TYPE; 
BEGIN 
	OPEN c_new_transactions; 
    LOOP
		FETCH c_new_transactions 
			INTO v_transaction_no, v_transaction_date, v_description, v_transaction_type, v_account_no, v_transaction_amount; 
			EXIT WHEN c_new_transactions%notfound;
             
			IF v_transaction_no is null 
				THEN raise_application_error(-20000, 'Error: Missing transaction number'); 
			END IF; 
			INSERT INTO transaction_history (transaction_no, transaction_date, description) 
				VALUES (v_transaction_no, v_transaction_date, v_description);  
                INSERT INTO transaction_detail (account_no, transaction_no, transaction_type, transaction_amount) 
				VALUES (v_account_no, v_transaction_no, v_transaction_type, v_transaction_amount);  
END LOOP;
END;

