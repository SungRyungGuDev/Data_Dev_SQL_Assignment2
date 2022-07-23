DECLARE 
	CURSOR c_new_transactions IS
		SELECT transaction_no, transaction_date, description, transaction_type, account_no, transaction_amount 
		FROM new_transactions 
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;
	CURSOR c_transaction_detail IS
		SELECT account_no, transaction_no, transaction_type, transaction_amount 
		FROM transaction_detail
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;
	CURSOR c_transaction_history IS 
		SELECT transaction_no, transaction_date, description
		FROM transaction_history 
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;
	CURSOR c_account IS 
		SELECT account_no, account_balance 
		FROM account 
		ORDER BY account_no
	FOR UPDATE NOWAIT;
	CURSOR c_error_log IS
		SELECT transaction_no, error_msg 
		FROM wkis_error_log 
		ORDER BY transaction_no
	FOR UPDATE NOWAIT;		
	--DECLARE using values
	v_transaction_no transaction_detail.transaction_no%TYPE; 
	v_transaction_date transaction_history.transaction_date%TYPE; 
	v_description transaction_history.description%TYPE; 
	v_transaction_type transaction_detail.transaction_type%TYPE; 
	v_account_no transaction_detail.account_no%TYPE; 
	v_transaction_amount transaction_detail.transaction_amount%TYPE; 
	v_account_balance account.account_balance%TYPE; 
	v_account_no_sum account.account_no%TYPE; 
	v_error_message wkis_error_log.error_msg%TYPE; 
	v_total_transaction_amount number := 0; 
	v_transaction_amount_sum number := 0; 
	v_debit_amount number := 0; 
	v_credit_amount number := 0; 
	v_transaction_type_count number := 0; 
	--DECLARE Error Exception
	v_debit_credit_not_equal EXCEPTION;
	v_missing_transaction_no EXCEPTION; 
	v_invalid_account_no EXCEPTION; 
	v_negative_value EXCEPTION; 
	v_invalid_transaction_type EXCEPTION; 
	v_sqlerrormsg VARCHAR2(50) := sqlerrm;
BEGIN 
	OPEN c_new_transactions; 
	OPEN c_transaction_detail; 
	OPEN c_transaction_history; 
	OPEN c_account; 
	OPEN c_error_log; 
	LOOP
		FETCH c_new_transactions 
			INTO v_transaction_no, v_transaction_date, v_description, v_transaction_type, v_account_no, v_transaction_amount; 
			EXIT WHEN c_new_transactions%notfound;
		SELECT account_balance INTO v_account_balance 
		FROM account 
		WHERE account_no = v_account_no_sum;
		BEGIN 
			IF v_transaction_no is null 
				THEN raise_application_error(-20000, 'Error: Missing transaction number'); 
			END IF; 
			INSERT INTO transaction_detail (account_no, transaction_no, 		transaction_type, transaction_amount) 
				VALUES (v_account_no, v_transaction_no, v_transaction_type, v_transaction_amount);  
			INSERT INTO transaction_history (transaction_no, transaction_date, description) 
				VALUES (v_transaction_no, v_transaction_date, v_description);  
			IF v_transaction_type = 'D' 
				THEN v_account_balance := v_account_balance + v_transaction_amount; 
				UPDATE account SET account_balance = v_account_balance 
				WHERE account_no = v_account_no_sum; 
			ELSE v_account_balance := v_account_balance - v_transaction_amount; 
				UPDATE account 
					SET account_balance = v_account_balance 
					WHERE account_no = v_account_no_sum; 
			END IF; 
			v_total_transaction_amount := 0; v_account_no_sum := v_account_no; 
		FETCH c_transaction_detail 
			INTO v_account_no, v_transaction_no, v_transaction_type, v_transaction_amount; 
			IF v_transaction_type = 'D' 
				THEN v_debit_amount := v_transaction_amount; 
			ELSE v_credit_amount := v_transaction_amount; 
			END IF; 
			WHILE v_account_no = v_account_no_sum 
			LOOP v_total_transaction_amount := v_total_transaction_amount + v_transaction_amount; v_account_no_sum := v_account_no; 
				FETCH c_transaction_detail 
					INTO v_account_no, v_transaction_no, v_transaction_type, v_transaction_amount; 
					IF v_transaction_type = 'D' 
						THEN v_debit_amount := v_debit_amount + v_transaction_amount; 
					ELSE v_credit_amount := v_credit_amount + v_transaction_amount; 
					END IF; 
			END LOOP; 
			IF v_debit_amount = v_credit_amount 
				THEN --If all is good then close transaction 
					INSERT INTO wkis_error_log (transaction_no, error_msg) 
						VALUES (v_transaction_no, 'No error'); 
				COMMIT; 
				--DeleteRecordFromNewTransactions 
				DELETE FROM new_transactions 
					WHERE transaction_no = v_transaction_no; v_debit_amount := 0; v_credit_amount := 0; 
			ELSE raise_application_error(-20001, 'Error: Debits and credits are not equal');
			END IF;
		END;
	END LOOP;
EXCEPTION 
--ExceptionHandlers 
	WHEN v_missing_transaction_no
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
			VALUES (v_transaction_no, 'Error: Missing transaction number'); 
	ROLLBACK; 
	WHEN v_invalid_account_no
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
			VALUES (v_transaction_no, 'Error: Invalid account number'); ROLLBACK; 
	WHEN v_negative_value 
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
			VALUES (v_transaction_no, 'Error: Negative value'); 
	ROLLBACK; 
	WHEN v_invalid_transaction_type 
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
		VALUES (v_transaction_no, 'Error: Invalid transaction type');
	ROLLBACK; 
	WHEN v_debit_credit_not_equal 
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
			VALUES (v_transaction_no, 'Error: Debits and credits are not equal'); 
	ROLLBACK; 
	WHEN OTHERS 
		THEN INSERT INTO wkis_error_log (transaction_no, error_msg) 
			VALUES (v_transaction_no, v_sqlerrormsg);
	ROLLBACK; 
END;