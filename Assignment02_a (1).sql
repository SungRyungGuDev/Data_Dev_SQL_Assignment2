DECLARE
	CURSOR c_new_transactions IS
		SELECT transaction_no, transaction_date, description, transaction_type, account_no, transaction_amount 
		FROM new_transactions 
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;
	CURSOR c_new_transactions_history IS
		SELECT DISTINCT transaction_no, transaction_date, description
		FROM new_transactions 
		ORDER BY transaction_no;
	CURSOR c_transactions_by_no(p_transaction_no new_transactions.transaction_no%TYPE) IS
		SELECT transaction_no, transaction_date, description, transaction_type, account_no, transaction_amount 
		FROM new_transactions
		WHERE transaction_no = p_transaction_no
	FOR UPDATE NOWAIT;
	v_transaction_no transaction_detail.transaction_no%TYPE; 
	v_transaction_date transaction_history.transaction_date%TYPE; 
	v_description transaction_history.description%TYPE; 
	v_transaction_type transaction_detail.transaction_type%TYPE; 
	v_account_no transaction_detail.account_no%TYPE; 
	v_transaction_amount transaction_detail.transaction_amount%TYPE; 
BEGIN
	FOR r_new_transactions_history IN c_new_transactions_history LOOP
		v_transaction_no := r_new_transactions_history.transaction_no;
		v_transaction_date := r_new_transactions_history.transaction_date;
		v_description := r_new_transactions_history.description;
	
		INSERT INTO transaction_history (transaction_no, transaction_date, description) 
			VALUES (v_transaction_no, v_transaction_date, v_description);
	FOR r_transactions_by_no IN c_transactions_by_no(v_transaction_no) LOOP
		v_transaction_type := r_transactions_by_no.transaction_type;
		v_account_no := r_transactions_by_no.account_no;
		v_transaction_amount := r_transactions_by_no.transaction_amount ;
		INSERT INTO transaction_detail (account_no, transaction_no,	transaction_type, transaction_amount) 
			VALUES (v_account_no, v_transaction_no, v_transaction_type, v_transaction_amount);
		END	LOOP;
	END LOOP;

	FOR r_new_transactions IN c_new_transactions LOOP
		v_transaction_type := r_new_transactions.transaction_type;
		v_account_no := r_new_transactions.account_no;
		v_transaction_amount := r_new_transactions.transaction_amount ;

		DBMS_OUTPUT.PUT_LINE(v_transaction_type); 
		DBMS_OUTPUT.PUT_LINE(v_account_no); 
		DBMS_OUTPUT.PUT_LINE(v_transaction_amount); 



END;